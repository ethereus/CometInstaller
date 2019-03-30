//
//  FirstViewController.m
//  Runner
//
//  Created by Tanay Findley on 2/18/19.
//  Copyright © 2019 Zero. All rights reserved.
//

#import "FirstViewController.h"
#include <sys/sysctl.h>
#include "jailD.h"
#import "Reachability.h"
#import <netdb.h>



@interface FirstViewController () {
    IBOutlet UILabel *statusLabel;
}


@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Set Shit
    NSString *stats = @"iOS Version: ";
    NSString *iOSVersion = [[UIDevice currentDevice] systemVersion];
    stats = [stats stringByAppendingString:iOSVersion];
    statusLabel.text = stats;
    
    //Internet
    
    if (![self isNetworkAvailable])
    {
        [self messageWithTitle:@"No Internet" message:@"Please connect to the internet and come back again."];
        return;
    }
    
    //Get Root
    if (![self isUnsandboxed] || getuid()) {
        [self testBtn:0];
    }
        
        
    //Setup
    if ([self isFirst])
    {
        [self setupDirs];
    }
}




//INTERNET

- (BOOL)isNetworkAvailable {
    char *hostname;
    struct hostent *hostinfo;
    hostname = "google.com";
    hostinfo = gethostbyname (hostname);
    if (hostinfo == NULL) return NO;
    else return YES;
}

- (void)messageWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    [alert show];
}



//END INTERNET


- (bool)isUnsandboxed {
    [[NSFileManager defaultManager] createFileAtPath:@"/var/TESTF" contents:nil attributes:nil];
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/TESTF"]) return false;
    [[NSFileManager defaultManager] removeItemAtPath:@"/var/TESTF" error:nil];
    return true;
}

- (bool)isFirst {
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/LIB/.installed_comet"])
        return true;
    return false;
}

- (void)setupDirs {
    [[NSFileManager defaultManager] createFileAtPath:@"/var/LIB/.installed_comet" contents:nil attributes:nil];
    [[NSFileManager defaultManager] createFileAtPath:@"/var/LIB/.comet_sources.list" contents:nil attributes:nil];
    [[NSFileManager defaultManager] createFileAtPath:@"/var/LIB/.comet_packages.list" contents:nil attributes:nil];
     [[NSFileManager defaultManager] createFileAtPath:@"/var/LIB/.comet_installed.list" contents:nil attributes:nil];
}


- (pid_t)pid_for_name:(NSString *)name {
    static int maxArgumentSize = 0;
    size_t size = sizeof(maxArgumentSize);
    sysctl((int[]){ CTL_KERN, KERN_ARGMAX }, 2, &maxArgumentSize, &size, NULL, 0);
    int mib[3] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL };
    struct kinfo_proc *info;
    size_t length;
    sysctl(mib, 3, NULL, &length, NULL, 0);
    info = malloc(length);
    sysctl(mib, 3, info, &length, NULL, 0);
    for (int i = 0; i < length / sizeof(struct kinfo_proc); i++) {
        pid_t pid = info[i].kp_proc.p_pid;
        if (pid == 0) {
            continue;
        }
        size_t size = maxArgumentSize;
        char *buffer = (char *)malloc(length);
        sysctl((int[]){ CTL_KERN, KERN_PROCARGS2, pid }, 3, buffer, &size, NULL, 0);
        NSString *executable = [NSString stringWithCString:buffer + sizeof(int) encoding:NSUTF8StringEncoding];
        free(buffer);
        if ([executable isEqual:name]) {
            free(info);
            return pid;
        } else if ([[executable lastPathComponent] isEqual:name]) {
            free(info);
            return pid;
        }
    }
    free(info);
    return -1;
}

- (IBAction)testBtn:(id)sender {
    
    calljailbreakd(getpid(), 6);
    calljailbreakd(getpid(), 7);
    static int tries = 0;
    sleep(1);
    setuid(0);
    seteuid(0);
    setgid(0);
    setegid(0);
    if (![self isUnsandboxed] || getuid()) {
        if (tries < 10) {
            tries++;
            [self testBtn:sender];
            return;
        } else {
            exit(0);
        }
    }
}



- (IBAction)respringBtn:(id)sender {
    kill([self pid_for_name:@"/System/Library/CoreServices/SpringBoard.app/SpringBoard"], SIGTERM);
}

- (IBAction)openTwitter:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/Chr0nicT"]];
}

- (IBAction)openTwitterComet:(id)sender {
     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/InstallComet"]];
}

@end
