//
//  ViewController.m
//  DropboxDatastoreMigration
//
//  Created by Phillip Harris on 8/24/14.
//  Copyright (c) 2014 Phillip Harris. All rights reserved.
//

#import "ViewController.h"

#import <Dropbox/Dropbox.h>

@interface ViewController ()

@property (nonatomic, strong) DBDatastore *localUnlinkedDatastore;
@property (nonatomic, strong) DBDatastore *linkedDatastore;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // DELETE EVERYTHING STORED REMOTELY IN DROPBOX - THIS IS LIKE A RESET BUTTON TO START FRESH AND TEST AGAIN
//    DBDatastoreManager *manager = [DBDatastoreManager managerForAccount:[[DBAccountManager sharedManager] linkedAccount]];
//    self.linkedDatastore = [DBDatastore openDefaultStoreForAccount:[[DBAccountManager sharedManager] linkedAccount] error:nil];
//    [self.linkedDatastore close];
//    [manager deleteDatastore:self.linkedDatastore.datastoreId error:nil];
//    [[[DBAccountManager sharedManager] linkedAccount] unlink];
//    self.linkedDatastore = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (IBAction)linkTapped:(id)sender {
    
    DBAccount *linkedAccount = [[DBAccountManager sharedManager] linkedAccount];
    
    if (!linkedAccount) {
        [self linkToDropbox];
    }
}

- (void)linkToDropbox {
    
    [[DBAccountManager sharedManager] addObserver:self block:^(DBAccount *account) {
        if ([account isLinked]) {
            [self didObserveLinkingToDropbox];
        }
    }];
    
    [[DBAccountManager sharedManager] linkFromController:self];
}

- (void)didObserveLinkingToDropbox {
    
    [[DBAccountManager sharedManager] removeObserver:self];
    
    [self addFirstTwoPresidents];
}

- (void)addFirstTwoPresidents {
    
    self.linkedDatastore = [DBDatastore openDefaultStoreForAccount:[[DBAccountManager sharedManager] linkedAccount] error:nil];
    
    DBDatastore *datastore = self.linkedDatastore;
    
    DBTable *houses = [datastore getTable:@"House"];
    
    BOOL inserted = NO;
    DBError *error = nil;
    DBRecord *theWhiteHouse = [houses getOrInsertRecord:@"TheWhiteHouse" fields:@{@"location": @"Washington, DC"} inserted:&inserted error:&error];
    
    DBList *orderedListOfResidents = [theWhiteHouse getOrCreateList:@"orderedListOfResidents"];
    
    DBTable *residents = [datastore getTable:@"Resident"];
    DBRecord *georgeWashington = [residents insert:@{@"name": @"George Washington"}];
    [orderedListOfResidents addObject:georgeWashington.recordId];
    
    DBRecord *johnAdams = [residents insert:@{@"name": @"John Adams"}];
    [orderedListOfResidents addObject:johnAdams.recordId];
    
    DBError *syncError = nil;
    [datastore sync:&syncError];
    
    NSLog(@"LINKING COMPLETE - CREATED LINKED DATASTORE AND ADDED FIRST TWO PRESIDENTS");
}

- (IBAction)unlinkTapped:(id)sender {
    
    [[[DBAccountManager sharedManager] linkedAccount] unlink];
    self.linkedDatastore = nil;
    
    [self addNextTwoPresidents];
}

- (void)addNextTwoPresidents {
    
    self.localUnlinkedDatastore = [DBDatastore openDefaultLocalStoreForAccountManager:[DBAccountManager sharedManager] error:nil];
    
    DBDatastore *datastore = self.localUnlinkedDatastore;
    
    DBTable *houses = [datastore getTable:@"House"];
    
    BOOL inserted = NO;
    DBError *error = nil;
    DBRecord *theWhiteHouse = [houses getOrInsertRecord:@"TheWhiteHouse" fields:@{@"location": @"Washington, DC"} inserted:&inserted error:&error];
    
    DBList *orderedListOfResidents = [theWhiteHouse getOrCreateList:@"orderedListOfResidents"];
    
    DBTable *residents = [datastore getTable:@"Resident"];
    DBRecord *thomasJefferson = [residents insert:@{@"name": @"Thomas Jefferson"}];
    [orderedListOfResidents addObject:thomasJefferson.recordId];
    
    DBRecord *jamesMadison = [residents insert:@{@"name": @"James Madison"}];
    [orderedListOfResidents addObject:jamesMadison.recordId];
    
    DBError *syncError = nil;
    [datastore sync:&syncError];
    
    NSLog(@"UNLINKING COMPLETE - CREATED LOCAL DATASTORE AND ADDED NEXT TWO PRESIDENTS");
}

- (IBAction)migrateTapped:(id)sender {
    
    [[DBAccountManager sharedManager] addObserver:self block:^(DBAccount *account) {
        if ([account isLinked]) {
            [self didObserveLinkingToDropboxForMigration];
        }
    }];
    
    [[DBAccountManager sharedManager] linkFromController:self];
}

- (void)didObserveLinkingToDropboxForMigration {
    
    [[DBAccountManager sharedManager] removeObserver:self];
    
    DBDatastoreManager *localManager = [DBDatastoreManager localManagerForAccountManager:[DBAccountManager sharedManager]];
    
    [self.localUnlinkedDatastore close];
    DBError *error = nil;
    DBDatastoreManager *linkedDatastoreManager = [localManager migrateToAccount:[[DBAccountManager sharedManager] linkedAccount] error:&error];
    
    self.linkedDatastore = [DBDatastore openDefaultStoreForAccount:[[DBAccountManager sharedManager] linkedAccount] error:nil];
    
    DBError *syncError = nil;
    [self.linkedDatastore sync:&syncError];
    
    NSLog(@"FINAL STEP REACHED - GO BROWSE DATASTORES ONLINE");
}

@end
