//
//  MTPhotosViewController.m
//  SecurePhotos
//
//  Created by Hefang Li on 9/15/15.
//  Copyright (c) 2015 hefang. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>

#import "RNDecryptor.h"
#import "RNEncryptor.h"
#import "MTPhotoCollectionViewCell.h"

#import "MTPhotosViewController.h"

@interface MTPhotosViewController () <UIActionSheetDelegate,
UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) NSMutableArray *photos;
@property (copy, nonatomic) NSString *filePath;

@end

@implementation MTPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Register cell classes
//    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    
    // Do any additional setup after loading the view.
    [self setupUserDirectory];
    [self prepareData];
}

- (IBAction)photos:(UIBarButtonItem *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:@"Select Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera", @"Photo Library", nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)setupUserDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [paths objectAtIndex:0];
    self.filePath = [documents stringByAppendingPathComponent:self.username];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:self.filePath]) {
        NSLog(@"Directory already present.");
        
    } else {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:self.filePath withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error) {
            NSLog(@"Unable to create directory for user.");
        }
    }
}

- (void)prepareData {
    self.photos = [[NSMutableArray alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.filePath error:&error];
    
    if ([contents count] && !error){
        NSLog(@"Contents of the user's directory. %@", contents);
        
        for (NSString *fileName in contents) {
            if ([fileName rangeOfString:@".securedData"].length > 0) {
                NSData *data = [NSData dataWithContentsOfFile:[self.filePath stringByAppendingPathComponent:fileName]];
                NSData *decryptedData = [RNDecryptor decryptData:data withSettings:kRNCryptorAES256Settings password:@"A_SECRET_PASSWORD" error:nil];
                UIImage *image = [UIImage imageWithData:decryptedData];
                [self.photos addObject:image];
                
            } else {
                NSLog(@"This file is not secured.");
            }
        }
        
    } else if (![contents count]) {
        if (error) {
            NSLog(@"Unable to read the contents of the user's directory.");
        } else {
            NSLog(@"The user's directory is empty.");
        }
    }
}

#pragma mark <UIImagePickerControllerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = [info objectForKey: UIImagePickerControllerEditedImage];
    
    if (!image) {
        [info objectForKey: UIImagePickerControllerOriginalImage];
    }
    
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *imageName = [NSString stringWithFormat:@"image-%u.securedData", self.photos.count + 1];
    NSData *encryptedImage = [RNEncryptor encryptData:imageData withSettings:kRNCryptorAES256Settings password:@"A_SECRET_PASSWORD" error:nil];
    [encryptedImage writeToFile:[self.filePath stringByAppendingPathComponent:imageName] atomically:YES];
    NSLog(@"filePath: %@", self.filePath);
    [self.photos addObject:image];
    [self.collectionView reloadData];
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark <UIActionSheetDelegate>

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex < 2) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.mediaTypes = @[(__bridge NSString *)kUTTypeImage];
        imagePickerController.allowsEditing = YES;
        imagePickerController.delegate = self;
        
        if (buttonIndex == 0) {
#if TARGET_IPHONE_SIMULATOR
            
#else
            imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
#endif
            
        } else if ( buttonIndex == 1) {
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        
        [self.navigationController presentViewController:imagePickerController animated:YES completion:nil];
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos ? self.photos.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MTPhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    cell.imageView.image = [self.photos objectAtIndex:indexPath.row];
    return cell;
}

@end
