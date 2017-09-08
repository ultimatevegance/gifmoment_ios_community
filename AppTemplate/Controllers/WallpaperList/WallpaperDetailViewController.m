//
//  WallpaperDetailViewController.m
//  AppTemplate
//
//  Created by Monster on 04/09/2017.
//  Copyright © 2017 MonsterTechStudio. All rights reserved.
//

#import "WallpaperDetailViewController.h"
#import "CollectionViewCell.h"
#import "YYWebImage.h"
#import "Common.h"
#import "FCAlertView.h"
#import <Photos/Photos.h>
@interface WallpaperDetailViewController ()<UIViewControllerTransitioningDelegate>
@property (weak, nonatomic) IBOutlet UIButton *previewButton;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIScrollView *previewScrollView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *toolBarView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) UIImage *wallpaperImage;
@property (strong, nonatomic) MSUserData *userData;
@property (copy, nonatomic) NSString *downloadSourceUrlString;

@end

@implementation WallpaperDetailViewController

- (instancetype)initWithSourceImage:(UIImage *)wallpaper DownloadUrl:(NSString *)downloadUrl User:(MSUserData *)user {
    self = [super init];
    if (self) {
        _wallpaperImage = wallpaper;
        _userData = user;
        _downloadSourceUrlString = downloadUrl;
        
    }
    return  self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [_imageView setImage:_wallpaperImage];
    _toolBarView.layer.cornerRadius = 8.f;
    _toolBarView.layer.masksToBounds = YES;
    ;
    [self configPreviewLayer];
    [self requestAuthorizationWithRedirectionToSettings];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

#pragma mark - Helpers

- (void)requestAuthorizationWithRedirectionToSettings {
    dispatch_async(dispatch_get_main_queue(), ^{
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusAuthorized)
        {
            //We have permission. Do whatever is needed
        }
        else
        {
            //No permission. Trying to normally request it
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status != PHAuthorizationStatusAuthorized)
                {
                    //User don't give us permission. Showing alert with redirection to settings
                    //Getting description string from info.plist file
                    NSString *accessDescription = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSPhotoLibraryUsageDescription"];
                    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:accessDescription message:@"To give permissions tap on 'Change Settings' button" preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Change Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }];
                    [alertController addAction:settingsAction];
                    
                    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
                }
            }];
        }
    });
}


- (void)configPreviewLayer {
    _previewScrollView.contentSize = CGSizeMake(kScreenWidth * 2, kScreenHeight - 20);
    UIImageView *homeScreenShootImageView = [[UIImageView alloc ]init];
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        /* Device is iPad */
        [homeScreenShootImageView setImage:[UIImage imageNamed:@"homeScreenIpad"]];
        
    } else {
        [homeScreenShootImageView setImage:[UIImage imageNamed:@"homeScreen"]];
    }
    homeScreenShootImageView.contentMode = UIViewContentModeScaleAspectFit;
    homeScreenShootImageView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight - 20);
    [_previewScrollView addSubview:homeScreenShootImageView];
    UIImageView *lockScreenShootImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lockScreen"]];
    lockScreenShootImageView.frame = CGRectMake(kScreenWidth, 0, kScreenWidth, kScreenHeight - 20);
    lockScreenShootImageView.contentMode = UIViewContentModeCenter;
    [_previewScrollView addSubview:lockScreenShootImageView];
    _previewScrollView.pagingEnabled = YES;
    _previewScrollView.hidden = YES;
    
    UITapGestureRecognizer *tapToDismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exitPreviewMode)];
    tapToDismiss.numberOfTapsRequired = 1;
    [_previewScrollView addGestureRecognizer:tapToDismiss];

}

- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo {
    [SVProgressHUD showSuccessWithStatus:@"Saved To Albums"];
}

#pragma mark - Actions

- (void)exitPreviewMode {
    [UIView transitionWithView:_previewScrollView
                      duration:0.7
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        _previewScrollView.hidden = YES;
                        _cancelButton.hidden = NO;
                        _toolBarView.hidden = NO;
                        
                    }
                    completion:NULL];

}

- (IBAction)cancel:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)preview:(UIButton *)sender {
    
    [UIView transitionWithView:_previewScrollView
                      duration:0.7
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        _previewScrollView.hidden = NO;
                        _toolBarView.hidden = YES;
                        _cancelButton.hidden = YES;

                    }
                    completion:NULL];

}

- (IBAction)save:(UIButton *)sender {
    if (_downloadSourceUrlString) {
        [_downloadSourceUrlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSURL *imageDownloadUrl = [NSURL URLWithString:_downloadSourceUrlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:imageDownloadUrl];
        NSURLSessionDownloadTask *downloadTask = [[MSNetworkAPIManager sharedClient] downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showProgress:downloadProgress.fractionCompleted status:@"Downloading"];
            });
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
            return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
//            NSLog(@"File downloaded to: %@", filePath);
            UIImage *downloadedImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
            UIImageWriteToSavedPhotosAlbum(downloadedImage,self,@selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:),NULL);
        }];
        [downloadTask resume];
    }
}

- (IBAction)showInfo:(UIButton *)sender {
    FCAlertView *infoAlertView = [[FCAlertView alloc] init];
    infoAlertView.darkTheme = YES;
    infoAlertView.customImageScale = 2;
    infoAlertView.animateAlertInFromTop = YES;
    infoAlertView.animateAlertOutToBottom = YES;
    infoAlertView.bounceAnimations = YES;
    infoAlertView.detachButtons = YES;
    infoAlertView.avoidCustomImageTint = YES;
    infoAlertView.titleFont = [UIFont systemFontOfSize:25 weight:20];
    NSString *userName = _userData.name;
    NSString *stats = [NSString stringWithFormat:@"%ld likes    &   %ld photos",(long)_userData.total_likes.integerValue,(long)_userData.total_photos.integerValue];
// TODO : show user avatar image
//    UIImage *userAvatar = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:_userData.profile_image]]];
    [infoAlertView showAlertWithTitle:userName withSubtitle:stats withCustomImage:[UIImage imageNamed:@"iconicButton"] withDoneButtonTitle:@"OK" andButtons:nil];
}

@end
