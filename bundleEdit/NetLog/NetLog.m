//
//  UDPLog.m
//  eyeSMS
//
//  Created by pete on 04/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "NetLog.h"
#import <UIKit/UIKit.h>
//#import <Foundation/NSException.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>


@implementation NetLog


static NSString* NetLog_Host = @"192.168.1.2";

static int  NetLog_Port = 9660;
static BOOL NetLog_Proto = SOCK_DGRAM;
static BOOL NetLog_Initialized = NO;
static BOOL NetLog_Active = YES;
static int  NetLog_BufferSize = 65536;
static NSString* NetLog_File = nil;
static NSDateFormatter *NetLog_DateFormatter = nil;
static NSString *NetLog_DeviceName = nil;

+(void)setupFromBundle {
    @try {
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        NSDictionary *log    = [info objectForKey:@"Log"];
        if ( log != nil ) {
            NSString *logHost	 = [log objectForKey:@"Host"]; 
            NSInteger logPort	 = [[log objectForKey:@"Port"] intValue];
            BOOL protoTCP		 = [[log objectForKey:@"forceTCP"] boolValue];
            NetLog_Active        = [[log objectForKey:@"Active"] boolValue];
            int BufferSize       = [[log objectForKey:@"BufferSize"] intValue];
            if ( BufferSize > 0 )
                NetLog_BufferSize = BufferSize;
            NetLog_File          = [log objectForKey:@"File"];
            [NetLog setup:logHost loggerPort:logPort protoTCP:protoTCP];
        }        
    } 
    @catch (NSException *ex) {
        NSLog(@"%@",ex);
    }
    @finally {
        NSLog(@"...");
    }
    
}

+(void)setup:(NSString*)fileName {
    if ( NetLog_Initialized == NO ) {
        NetLog_DateFormatter = [[NSDateFormatter alloc] init];
        [NetLog_DateFormatter setDateStyle:NSDateFormatterShortStyle];
        [NetLog_DateFormatter setTimeStyle:NSDateFormatterMediumStyle]; 
        NetLog_Initialized = YES;
        NetLog_File = [NSString stringWithString:fileName];
        NetLog_DeviceName = [UIDevice currentDevice].name;
    }
}

+(void)setup:(NSString*)loggerHost loggerPort:(int)logPort protoTCP:(BOOL)isTCP {
	NetLog_Host = loggerHost; //[[NSString alloc] initWithString:loggerHost];
	NetLog_Port = logPort;
	NetLog_Proto = isTCP?SOCK_STREAM:SOCK_DGRAM;
	NetLog_Initialized = YES;
    /*
    NSError *error = nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:NetLog_File] == YES) {        
        [fileManager removeItemAtPath:NetLog_File error:&error];
    }
     */
     
}

+(void)log:(NSString*)formatString,... {

    //NSString *logFile = NetLog_File;//@"/private/var/mobile/NetLog.log";
	va_list argList;
	va_start(argList,formatString);
	NSString *message = [[NSString alloc] initWithFormat:formatString arguments:argList]; 
	va_end(argList);
	
    //[NetLog setup:@""];
    
    NSDate *now = [NSDate date];
    NSString *dt  = [NetLog_DateFormatter stringFromDate:now];
    NSString *msg = [[NSString alloc] initWithFormat:@"%@ | [%@] %@",dt,NetLog_DeviceName,message];
    
    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [NetLog send:data];
    
    /*
	if ( NetLog_Initialized == YES && NetLog_Active == YES ) {
		//[NSException raise:@"NetLog logger IP is not set" format:@"%@",@"Call the +(void)setup method at first..."];  
        NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    }
    */
    /*
    NSError *error = nil;
    NSStringEncoding encoding;
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *offlineFile = [docsPath stringByAppendingPathComponent:@"NetLog.txt"];
    NSString *sData = [[NSString alloc] init];//[NSString stringWithContentsOfFile:offlineFile usedEncoding:&encoding error:&error];

    sData = [sData stringByAppendingString:msg];
    error = nil;
    BOOL ok = [sData writeToFile:offlineFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if ( error != nil )
        alert(@"Write Failed",@"%@,%@",offlineFile,[error localizedDescription]);
    
    if ( ok == NO )
        alert(@"Cannot write",@"%@\n%s",msg,strerror(errno));
    */
	NSLog(@"%@",msg);
}


+(void)send:(NSData*) data  {
	
    const char *pData = (const char*)[data bytes];
    int length = [data length];
    const char *fileName = [NetLog_File cStringUsingEncoding:NSUTF8StringEncoding];
    FILE *fd = fopen(fileName,"a+t");
    if ( fd ) {
        if ( fwrite(pData,1,length,fd) == -1 ) 
            alert(@"write",@"cannot write %s\n",strerror(errno));
        fclose(fd);
    } else {
        alert(@"File",@"Cannot create %s\n",strerror(errno));
    }
    //alert(@"sending udp",@"%@:%d\n",NetLog_Host,NetLog_Port);
    
    //int nWritten = -1;
    
	int sock = socket(AF_INET,NetLog_Proto,0);
	if ( sock == -1 ){
		alert(@"udp",@"Cannot create socket %s\n",strerror(errno));
		return;
	}
	
#ifndef _NETLOG_CHUNKED_    
    int newMaxBuff = 512000; //length * 2;
    setsockopt(sock, SOL_SOCKET, SO_SNDBUF, &newMaxBuff, sizeof(newMaxBuff));    
#endif    
    struct sockaddr_in sa = {0};
	sa.sin_len  = sizeof ( struct sockaddr_in );
	sa.sin_port = htons(NetLog_Port);
	sa.sin_family = AF_INET;
	inet_aton([NetLog_Host UTF8String],&sa.sin_addr);

    if ( NetLog_Proto == SOCK_STREAM )
        if ( connect(sock,(struct sockaddr*)&sa,sizeof(struct sockaddr_in)) == -1 )
            return;
    
    int nSended = 0;
    
    if ( NetLog_Proto == SOCK_DGRAM )
        if ( -1 == sendto(sock,pData,length,0,(struct sockaddr*)&sa,sizeof(struct sockaddr_in)) )
            alert(@"udp",@"Cannot send to %@:%d => %s\n",NetLog_Host,NetLog_Port,strerror(errno));
    else
        nSended += send(sock,pData,length,0);

    close(sock);

}

+ (void) alert2:(NSString*) title formatStr:(NSString*) fmtStr,... {
	
    NSUserDefaults *uDef = [NSUserDefaults standardUserDefaults];
    BOOL fSilent = [uDef boolForKey:@"Background"];
    
    
	va_list argList;
	va_start(argList,fmtStr);
	NSString *message = [[NSString alloc] initWithFormat:fmtStr arguments:argList]; 
	va_end(argList);
    
    if ( fSilent == YES ) {
        netlog(@"SILENT: %@\n",message);
        return;
    }
    
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[alertView show];
	NSLog(@"%@",message);
	//[alertView release];	
}

+ (void) alert:(NSString*) fmtStr,... {
	
    NSUserDefaults *uDef = [NSUserDefaults standardUserDefaults];
    BOOL fSilent = [uDef boolForKey:@"Background"];
        
    
	va_list argList;
	va_start(argList,fmtStr);
	NSString *message = [[NSString alloc] initWithFormat:fmtStr arguments:argList]; 
	va_end(argList);

    if ( fSilent == YES ) {
        netlog(@"SILENT: %@\n",message);
        return;
    }
    
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Kitty Says..." message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	
	[alertView show];
	NSLog(@"%@",message);
	//[alertView release];	
}

+(void)debugPID {
    
    int pid = getpid(); 
    FILE *fd    = fopen("/var/mobile/bones.pid","w+t");
    if ( fd ) {
        fprintf(fd,"%d",pid);
        fclose(fd);
    }
    
}

@end








