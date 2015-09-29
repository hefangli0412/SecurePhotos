//
//  MTViewController.m
//  SecurePhotos
//
//  Created by Hefang Li on 9/15/15.
//  Copyright (c) 2015 hefang. All rights reserved.
//
#import "SSKeychain.h"
#import "MTAppDelegate.h"
#import "MTPhotosViewController.h"

#import "MTViewController.h"

@interface MTViewController () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation MTViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    MTAppDelegate *applicationDeleagte = (MTAppDelegate *)[[UIApplication sharedApplication] delegate];
    [applicationDeleagte setNavigationController:self.navigationController];
}

- (IBAction)login:(UIButton *)sender {
    if (self.usernameTextField.text.length > 0 && self.passwordTextField.text.length > 0) {
        NSString *password = [SSKeychain passwordForService:@"MyPhotos" account:self.usernameTextField.text];
        
        if (password.length > 0) {
            if ([self.passwordTextField.text isEqualToString:password]) {
                [self performSegueWithIdentifier:@"photosViewController" sender:nil];
                
            } else {
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Error Login" message:@"Invalid username/password combination." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            }
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Account" message:@"Do you want to create an account?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            [alertView show];
        }
        
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Input" message:@"Username and/or password cannot be empty." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            break;
        case 1:
            [self createAccount];
            break;
        default:
            break;
    }
}

- (void)createAccount {
    BOOL result = [SSKeychain setPassword:self.passwordTextField.text forService:@"MyPhotos" account:self.usernameTextField.text];
    
    if (result) {
        [self performSegueWithIdentifier:@"photosViewController" sender:nil];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    MTPhotosViewController *photosViewController = segue.destinationViewController;
    photosViewController.username = self.usernameTextField.text;
    self.passwordTextField.text = nil;
}


@end
