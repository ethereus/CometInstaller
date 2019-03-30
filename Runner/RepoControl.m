//
//  RepoControl.m
//  Runner
//
//  Created by Tanay Findley on 2/19/19.
//  Copyright © 2019 Zero. All rights reserved.
//

#import "RepoControl.h"

@interface RepoControl ()
{
    NSMutableArray *repoArray;
    IBOutlet UITableView *tblView;
    IBOutlet UITableView *searchTable;
}

@end

@implementation RepoControl

- (void)viewDidLoad {
    [super viewDidLoad];
    
    repoArray = [[NSMutableArray alloc]init];
    //Read From Source File
    [repoArray removeAllObjects];
    [self readSources];
    [self calcSources];
    tblView.reloadData;
    //Add To Mutable Array
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return repoArray.count;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    
    NSURL *newUrl = [NSURL URLWithString:[[repoArray objectAtIndex:indexPath.row] stringByAppendingString:@"/RepoName"]];
    NSString *repoName = [[[NSString stringWithContentsOfURL:newUrl]componentsSeparatedByString:@"CRepoName:"]objectAtIndex:1];
    
    
    //Image
    NSURL *imageUrl = [NSURL URLWithString:[[repoArray objectAtIndex:indexPath.row] stringByAppendingString:@"/RepoIcon.png"]];
    NSData *imgData = [NSData dataWithContentsOfURL:imageUrl];
    
    UIImage *cellImage = [UIImage imageWithData:imgData];
    
    
    
    cell.textLabel.text = repoName;
    cell.imageView.image = cellImage;
    
    //cell.textLabel.text = [repoArray objectAtIndex:indexPath.row];
    
    return cell;
}



- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSString *textFile = [NSString stringWithContentsOfFile:@"/var/LIB/.comet_sources.list"];
        NSArray *lines = [textFile componentsSeparatedByCharactersInSet:
                          [NSCharacterSet newlineCharacterSet]];
        NSString *relevantLine = [lines objectAtIndex:indexPath.row];
        
        [self removeSource:relevantLine];
        [self readSources];
        [self calcSources];
        tblView.reloadData;
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        
    }
}



//VOID

- (void)removeSource:(NSString *)source
{
    NSMutableData *data;
    NSString *newSource = [NSString stringWithFormat:@"%@%s", source, "\n"];
    NSString *textFile = [NSString stringWithContentsOfFile:@"/var/LIB/.comet_sources.list"];
    
    textFile = [textFile stringByReplacingOccurrencesOfString:newSource withString:@""];
    const char *bytestring = [textFile cStringUsingEncoding:NSASCIIStringEncoding];
    data = [NSMutableData dataWithBytes:bytestring length:strlen(bytestring)];
    [data writeToFile:@"/var/LIB/.comet_sources.list" atomically:YES];
    
    
    //Now we have to remove those packages... I know, fuck. Stresses me out, too.
    [self removeSource2:source];
    
}

- (void)removeSource2:(NSString *)source
{
    NSMutableData *data;
    
    NSString *url = [NSString stringWithFormat:@"%@%s", source, "/Packages.comet"];
    NSURL *newUrl = [NSURL URLWithString:url];
    NSString *newSource = [NSString stringWithContentsOfURL:newUrl];
    
    NSString *textFile = [NSString stringWithContentsOfFile:@"/var/LIB/.comet_packages.list"];
    
    textFile = [textFile stringByReplacingOccurrencesOfString:newSource withString:@""];
    const char *bytestring = [textFile cStringUsingEncoding:NSASCIIStringEncoding];
    data = [NSMutableData dataWithBytes:bytestring length:strlen(bytestring)];
    [data writeToFile:@"/var/LIB/.comet_packages.list" atomically:YES];
    
    
}

- (void)calcSources {
    
    //Read Lines
    NSString *textFile = [NSString stringWithContentsOfFile:@"/var/LIB/.comet_sources.list"];
    [[NSFileManager defaultManager] removeItemAtPath:@"/var/LIB/.comet_packages.list" error:nil];
    [[NSFileManager defaultManager] createFileAtPath:@"/var/LIB/.comet_packages.list" contents:nil attributes:nil];
    [textFile enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        if ([line length] > 0) {
            NSMutableData *data;
            NSString *url = [line stringByAppendingString:@"/Packages.comet"];
            NSURL *newUrl = [NSURL URLWithString:url];
            NSFileHandle *file;
            
            file = [NSFileHandle fileHandleForUpdatingAtPath: @"/var/LIB/.comet_packages.list"];
            
            //Read Packages.comet
            NSString *textFile = [NSString stringWithContentsOfURL:newUrl];
            
            
            const char *bytestring = [textFile cStringUsingEncoding:NSASCIIStringEncoding];
            data = [NSMutableData dataWithBytes:bytestring length:strlen(bytestring)];
            
            
            [file seekToEndOfFile];
            [file writeData:data];
            [file closeFile];
        }
    }];
    
}

- (void)readSources {
    [repoArray removeAllObjects];
    
    NSString *textFile = [NSString stringWithContentsOfFile:@"/var/LIB/.comet_sources.list"];
    
    [textFile enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        if ([line length] > 0) {
            [repoArray addObject:line];
        }
    }];
    
}

- (IBAction)addSource:(id)sender {
    UIAlertController * alertController = [UIAlertController
    alertControllerWithTitle: @"Add Repo" message: @"Input Repo URL" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"URL";
        textField.textColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * namefield = textfields[0];
        //Append to source
        NSFileHandle *file;
        NSMutableData *data;
        NSString *url = [NSString stringWithFormat:@"%@%s", namefield.text, "\n"];
        
        
        
        //IS THE REPO VALID??? FEK WE'LL NEVER KNOW LMAOJKWATCHTHISREDNECKSHIT
        NSString *preUrl = [namefield.text stringByAppendingString:@"/RepoName"];
        NSURL *newUrl = [NSURL URLWithString:preUrl];
        //LMAO HERE WE GO XA-DEEEE
        NSString *repoNameShit = [NSString stringWithContentsOfURL:newUrl encoding:NSASCIIStringEncoding error:nil];
        
        if ([repoNameShit hasPrefix:@"CRepoName:"])
        {
            const char *bytestring = [url cStringUsingEncoding:NSASCIIStringEncoding];
            data = [NSMutableData dataWithBytes:bytestring length:strlen(bytestring)];
            file = [NSFileHandle fileHandleForUpdatingAtPath: @"/var/LIB/.comet_sources.list"];
            [file seekToEndOfFile];
            [file writeData: data];
            [file closeFile];
            
            [self readSources];
            tblView.reloadData;
            [self calcSources];
        } else {
            [self dismissController:@"Error" message:@"This Repo Is Not Valid!"];
        }
    }]];
    
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alertController addAction:dismiss];
    [self presentViewController:alertController animated:YES completion:nil];
    
}




//EDITING
- (IBAction)editButton:(id)sender {
    if (tblView.isEditing)
    {
        [sender setTitle:@"Edit" forState:UIControlStateNormal];
        tblView.editing = false;
    } else {
        [sender setTitle:@"Done" forState:UIControlStateNormal];
        tblView.editing = true;
    }
}

- (void)dismissController:(NSString *)title message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [alert show];
}

//REFRESH
- (IBAction)refreshButton:(id)sender {
    [self dismissController:@"Reloading" message:@"Please Wait"];
    [repoArray removeAllObjects];
    [self readSources];
    [self calcSources];
    tblView.reloadData;
}

@end
