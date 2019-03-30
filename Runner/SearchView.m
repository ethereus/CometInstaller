//
//  SearchView.m
//  Runner
//
//  Created by Tanay Findley on 2/19/19.
//  Copyright © 2019 Zero. All rights reserved.
//


#import "SearchView.h"
#import "SSZipArchive/SSZipArchive.h"
#include <sys/sysctl.h>
#include <sys/stat.h>
#include <spawn.h>
#import <mach/mach.h>
#import <dlfcn.h>
#import <sys/utsname.h>

#define execute(ARGS) \
{\
pid_t _____PID_____;\
posix_spawn(&_____PID_____, ARGS[0], NULL, NULL, (char **)&ARGS, NULL);\
waitpid(_____PID_____, NULL, 0);\
}

@interface SearchView ()
{
    NSMutableArray *searchArray;
    NSMutableArray *fileArray;
    NSMutableArray *blacklistArray;
    NSMutableArray *uninsArray;
    IBOutlet UITableView *tblView;
    IBOutlet UISearchBar *searchBar;
    NSString *Resources;
}

@end

@implementation SearchView



- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Init Array
    fileArray = [[NSMutableArray alloc]init];
    [fileArray removeAllObjects];
    
    blacklistArray = [[NSMutableArray alloc]init];
    [blacklistArray removeAllObjects];
    
    uninsArray = [[NSMutableArray alloc]init];
    [uninsArray removeAllObjects];
    
    
    searchArray = [[NSMutableArray alloc]init];
    [searchArray removeAllObjects];
    [self loadArray];
    
    Resources = [[NSBundle mainBundle] bundlePath];
    
    
    
    //BLACKLIST
    //SET BLACKLIST
    [blacklistArray addObject:@"PreferenceLoader"];
    [blacklistArray addObject:@"PreferenceBundles"];
    [blacklistArray addObject:@"Frameworks"];
    [blacklistArray addObject:@"PreferenceLoader/Preferences"];
    [blacklistArray addObject:@"MobileSubstrate"];
    [blacklistArray addObject:@"MobileSubstrate/DynamicLibraries"];
    [blacklistArray addObject:@"Themes"];
    [blacklistArray addObject:@"Application Support"];
    
    
    tblView.reloadData;
    
}

//SEARCH
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    if (searchText.length > 0)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF beginswith [search] %@", searchBar.text];
    
        NSArray *matches = [searchArray filteredArrayUsingPredicate:predicate];
        [searchArray removeAllObjects];
        [searchArray addObjectsFromArray:matches];
    
        tblView.reloadData;
    } else {
        [self loadArray];
    }
    
}



- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

//TABLE
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return searchArray.count;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *fileURL = [[[searchArray objectAtIndex:indexPath.row] componentsSeparatedByString:@" At: "]objectAtIndex:1];
    
    NSString *fileName = [[[searchArray objectAtIndex:indexPath.row] componentsSeparatedByString:@" At: "]objectAtIndex:0];
    
    [self selectedItem:fileName url:fileURL];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell2" forIndexPath:indexPath];
    
    NSString *fileName = [[[searchArray objectAtIndex:indexPath.row] componentsSeparatedByString:@" At: "]objectAtIndex:0];
    
    
    
    //[searchArray objectAtIndex:indexPath.row] = FileName At: FileURL
    
    cell.textLabel.text = fileName;
    
    return cell;
}

//LOAD ARRAY
- (void)loadArray {
    [searchArray removeAllObjects];
    NSString *textFile = [NSString stringWithContentsOfFile:@"/var/LIB/.comet_packages.list"];
    
    [textFile enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        if ([line length] > 0) {
            NSString *newLine = [line stringByReplacingOccurrencesOfString:@"FileName(" withString:@""];
            NSString *newLine2 = [newLine stringByReplacingOccurrencesOfString:@"):COMETFile(" withString:@" At: "];
            NSString *newLine3 = [newLine2 stringByReplacingOccurrencesOfString:@")" withString:@""];
            [searchArray addObject:newLine3];
        }
    }];
    
}

- (IBAction)reload:(id)sender {
    [searchArray removeAllObjects];
    [self loadArray];
    tblView.reloadData;
}

//ACTIONED UIVIEW
- (IBAction)selectedItem:(NSString *)title url:(NSString *)url {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Install" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        //Install The File (Download, Extract, Kill SpringBoard)
        
        [self fileRunner:url title:title];
        
        
        
        
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Uninstall" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        //Uninstall The File (Remove dirs, Kill SpringBoard)
        
        [self fileUninstaller:url title:title];
    }]];
    
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    
    [alertController addAction:dismiss];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

//
- (void)messageWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    [alert show];
}


- (void)fileRunner:(NSString *)url title:(NSString *)title{
    [self messageWithTitle:@"Comet" message:@"Installing your file... Do not shut off the device!"];
    
    if ([self downloadFile:url])
    {
        [self setInstalled:url fileName:title];
        [self installFile];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        [self messageWithTitle:@"ERROR" message:@"The file failed to download!"];
    }
}

- (void)setInstalled:(NSString *)url fileName:(NSString *)fileName {
    //FileName(Cylinder):COMETFile(https://raw.githubusercontent.com/Chr0nicT/CometRepo/master/Files/Cylinder.zip)
    
    NSString *pre1 = [@"FileName(" stringByAppendingString:fileName];
    NSString *pre2 = [pre1 stringByAppendingString:@"):COMETFile("];
    NSString *pre3 = [pre2 stringByAppendingString:url];
    NSString *finalText = [pre3 stringByAppendingString:@")\n"];
    
    NSData *dataToWrite = [finalText dataUsingEncoding:NSASCIIStringEncoding];
    
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath: @"/var/LIB/.comet_installed.list"];
    
    [file seekToEndOfFile];
    [file writeData: dataToWrite];
    [file closeFile];
    
}


- (void)setUninstalled:(NSString *)url fileName:(NSString *)fileName {
    //FileName(Cylinder):COMETFile(https://raw.githubusercontent.com/Chr0nicT/CometRepo/master/Files/Cylinder.zip)
    
    //Load Array
    [uninsArray removeAllObjects];
    NSString *textFile = [NSString stringWithContentsOfFile:@"/var/LIB/.comet_installed.list"];
    
    [textFile enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        if ([line length] > 0) {
            [uninsArray addObject:line];
        }
    }];
    // Done
    
    
    
    NSString *pre1 = [@"FileName(" stringByAppendingString:fileName];
    NSString *pre2 = [pre1 stringByAppendingString:@"):COMETFile("];
    NSString *pre3 = [pre2 stringByAppendingString:url];
    NSString *finalText = [pre3 stringByAppendingString:@")"];
    
    
    if ([uninsArray containsObject:finalText])
    {
        [uninsArray removeObject:finalText];
    }
    
    
    [[NSFileManager defaultManager]removeItemAtPath:@"/var/LIB/.comet_installed.list" error:nil];
    [[NSFileManager defaultManager]createFileAtPath:@"/var/LIB/.comet_installed.list" contents:nil attributes:nil];
    
    for (NSString *textToWrite in uninsArray)
    {
        NSData *dataToWrite = [[textToWrite stringByAppendingString:@"\n"] dataUsingEncoding:NSASCIIStringEncoding];
        
        NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath: @"/var/LIB/.comet_installed.list"];
        
        [file seekToEndOfFile];
        [file writeData: dataToWrite];
        [file closeFile];
    }
    
}

- (void)fileUninstaller:(NSString *)url title:(NSString *)title{
    [self messageWithTitle:@"Comet" message:@"Uninstalling your file... Do not shut off the device!"];
    
    if ([self downloadFile:url])
    {
        [self setUninstalled:url fileName:title];
        [self uninstallFile];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        [self messageWithTitle:@"ERROR" message:@"The file failed to download!"];
    }
}

- (void)uninstallFile {
    NSString *file = [Resources stringByAppendingString:@"/tweak.zip"];
    NSString *pkg = @"/var/LIB/tweakUnzipped";
    
    [SSZipArchive unzipFileAtPath:file toDestination:pkg];
    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
    
    //Iterate
    
    [self openEachFileAt:pkg];
    

    
    //Remove Blacklisted Items
    for (NSString *strToRem in blacklistArray)
    {
        if ( [fileArray containsObject:strToRem] )
        {
            [fileArray removeObject:strToRem];
        }
    }
    
    
    for (int i = 0; i < fileArray.count; i++)
    {
    
    
        NSString *file2 = [NSString stringWithUTF8String:[[fileArray objectAtIndex:i] UTF8String]];
        
        NSString *fileToRem = [@"/var/LIB/" stringByAppendingString:file2];
        
        [[NSFileManager defaultManager] removeItemAtPath:fileToRem error:nil];
        
    
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:pkg error:nil];
    [self respring];
    
}


- (void)openEachFileAt:(NSString*)path
{
    NSString* file;
    NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
    
    
    while (file = [enumerator nextObject])
    {
        // check if it's a directory
        BOOL isDirectory = NO;
        NSString* fullPath = [path stringByAppendingPathComponent:file];
        [[NSFileManager defaultManager] fileExistsAtPath:fullPath
                                             isDirectory: &isDirectory];
        
        NSString *theFile = [[[fullPath componentsSeparatedByString:@"tweakUnzipped/"]objectAtIndex:1]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        
        
        
        if ( ! [fileArray containsObject:theFile] )
        {
            [fileArray addObject:theFile];
        }
    }
    
}


- (int)downloadFile:(NSString *)url {
    NSString *file = [Resources stringByAppendingString:@"/tweak.zip"];
    NSURL *nURL = [NSURL URLWithString:url];
    if (![nURL.pathExtension.lowercaseString isEqual:@"zip"])
    {
        return NO;
    }
    
    //INIT DOWNLOAD
    NSData *data = [NSData dataWithContentsOfURL:nURL];
    if (data) {
        [data writeToFile:file atomically:YES];
        return YES;
    } else {
        return NO;
    }
}


- (void)installFile {
    NSString *file = [Resources stringByAppendingString:@"/tweak.zip"];
    NSString *pkg = @"/var/LIB/";
    
    [SSZipArchive unzipFileAtPath:file toDestination:pkg];
    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
    [self patch];
}

- (void)patch {
    //Inject it to avoid reboot stuff
    NSArray *applications = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/LIB/PreferenceBundles/" error:NULL];
    
    for (NSString *string in applications) {
        NSString *fullPath = [@"/var/LIB/PreferenceBundles/" stringByAppendingString:string];
        
        NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Info.plist",fullPath]];
        
        
        NSString *executable = [infoPlist objectForKey:@"CFBundleExecutable"];
        
        NSString *injectThis = [NSString stringWithFormat:@"%@/%@", fullPath, executable];
        
        
        //SIGN
        [self sign:injectThis];
        
        [self trust:injectThis];
    }
    //usleep(5000000);
    
    //INJECT
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/LIB/MobileSubstrate/DynamicLibraries/" error:nil];
    NSArray *dylibFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.dylib'"]];
    
    
    //SIGN
    for (NSString *uDylibFile in dylibFiles)
    {
        NSString *dylib2 = [@"/var/LIB/MobileSubstrate/DynamicLibraries/" stringByAppendingString:uDylibFile];
        [self sign:dylib2];
    }
    
    //INJECT
    for (NSString *dylibFile in dylibFiles)
    {
        NSString *dylib = [@"/var/LIB/MobileSubstrate/DynamicLibraries/" stringByAppendingString:dylibFile];
        [self trust:dylib];
    }
    
    [self respring];
}




//RESPRING
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

- (void)respring {
    kill([self pid_for_name:@"/System/Library/CoreServices/SpringBoard.app/SpringBoard"], SIGTERM);
}

- (void)trust:(NSString *)path {
    // trustcache
    const char *args[] = {"/var/containers/Bundle/iosbinpack64/usr/bin/inject", path.UTF8String, NULL};
    execute(args);
}

- (void)sign:(NSString *)path {
    // trustcache
    const char *args[] = {"/var/containers/Bundle/iosbinpack64/bin/ldid2", "-S", path.UTF8String};
    execute(args);
}


@end
