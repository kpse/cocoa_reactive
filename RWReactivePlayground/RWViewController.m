//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RWViewController ()

@property(weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property(weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property(weak, nonatomic) IBOutlet UIButton *signInButton;
@property(weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property(strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];

//  [self updateUIState];

  self.signInService = [RWDummySignInService new];

  // handle text changes for both text fields
  // initially hide the failure message
  self.signInFailureText.hidden = YES;

  [[[self.usernameTextField.rac_textSignal
    map:^id(NSString *text){
      return @(text.length);
    }]
    filter:^BOOL(NSNumber *length) {
      return [length integerValue] > 3;
    }]
    subscribeNext:^(id x) {
    NSLog(@"%@", x);
  }];

  RACSignal *validUsernameSignal = [self.usernameTextField.rac_textSignal
    map:^id(NSString *text){
      return @([self isValidUsername:text]);
    }];
  RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal
    map:^id(NSString *text){
      return @([self isValidPassword:text]);
    }];

  RAC(self.passwordTextField, backgroundColor) =
    [validPasswordSignal
      map:^id(NSNumber *passwordValid){
      return [passwordValid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
    }];

  RAC(self.usernameTextField, backgroundColor) =
    [validUsernameSignal
      map:^id(NSNumber *valid){
      return [valid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
    }];

  RACSignal *signUp = [RACSignal combineLatest:@[validPasswordSignal, validUsernameSignal] reduce:^id(NSNumber *username, NSNumber *password){
    return @([username boolValue] && [password boolValue]);
  }];

  [signUp subscribeNext:^(NSNumber *signUpSigal) {
    self.signInButton.enabled = [signUpSigal boolValue];
  }];

  [[[[self.signInButton
    rac_signalForControlEvents:UIControlEventTouchUpInside]
    doNext:^(id x) {
      self.signInButton.enabled = NO;
      self.signInFailureText.hidden = YES;
    }]
    flattenMap:^RACStream *(id value) {
      return [self signInSigal];
    }]
    subscribeNext:^(id x) {
    self.signInButton.enabled = YES;
    BOOL success = [x boolValue];
    self.signInFailureText.hidden = success;
    if (success) {
      [self performSegueWithIdentifier:@"signInSuccess" sender:self];
    }
  }];
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}

- (RACSignal *)signInSigal {
  return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
    [self.signInService signInWithUsername:self.usernameTextField.text password:self.passwordTextField.text
                                  complete:^(BOOL success) {
      [subscriber sendNext:@(success)];
      [subscriber sendCompleted];
    }];
    return nil;
  }];
}


// updates the enabled state and style of the text fields based on whether the current username
// and password combo is valid

@end
