//
//  IRISRootViewController.m
//  IRIS
//
//  Created by Taylan Pince on 2015-08-17.
//  Copyright (c) 2015 Hipo. All rights reserved.
//

#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OEPocketsphinxController.h>
#import <OpenEars/OEFliteController.h>
#import <OpenEars/OEAcousticModel.h>
#import <OpenEars/OEEventsObserver.h>
#import <Slt/Slt.h>
#import <CommonCrypto/CommonDigest.h>

#import "AFHTTPRequestOperationManager.h"
#import "PureLayout.h"

#import "IRISRootViewController.h"

#import "NSString+HPHashAdditions.h"


#define kFileName @"language-model-files"
#define kAcousticModel @"AcousticModelEnglish"


@interface IRISRootViewController () <OEEventsObserverDelegate>

@property (nonatomic, strong) OELanguageModelGenerator *languageModelGenerator;
@property (nonatomic, strong) OEFliteController *fliteController;
@property (nonatomic, strong) Slt *slt;
@property (nonatomic, strong) OEEventsObserver *openEarsEventsObserver;
@property (nonatomic, strong) AFHTTPRequestOperationManager *requestOperationManager;

@property (nonatomic, strong) NSDictionary *recognizedCommands;
@property (nonatomic, strong) NSString *languageModelPath;
@property (nonatomic, strong) NSString *dictionaryPath;
@property (nonatomic, strong) NSString *floorNumberString;
@property (nonatomic, strong) NSString *on_off;

@property (nonatomic, strong) UIButton *micControlButton;
@property (nonatomic, strong) UILabel *recognizedText;
@property (nonatomic, strong) UILabel *recognizableText;

@end


@implementation IRISRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    [self createUI];
    
    _requestOperationManager = [AFHTTPRequestOperationManager manager];
    
    _fliteController = [[OEFliteController alloc] init];
    _slt = [[Slt alloc] init];
    [_fliteController setDuration_stretch:1.3];
    
    _openEarsEventsObserver = [[OEEventsObserver alloc] init];
    [_openEarsEventsObserver setDelegate:self];
    
    _languageModelGenerator = [[OELanguageModelGenerator alloc] init];
    
    /*
     @{
     ThisWillBeSaidOnce : @[ // Lights
     @{ ThisWillBeSaidOnce : @[@"HEY IRIS"] },
     @{ OneOfTheseWillBeSaidOnce : @[@"TURN ON LIGHTS", @"TURN OFF LIGHTS"] },
     @{ OneOfTheseWillBeSaidOnce : @[@"FLOOR ONE", @"FLOOR TWO", @"FLOOR THREE"] },
     @{ ThisCanBeSaidOnce : @[@"THANK YOU"] }
     ]
     };
     */
    
    /*
     @{
     ThisWillBeSaidOnce : @[ @{ ThisWillBeSaidOnce : @[@"HEY IRIS"] },
     @{ OneOfTheseWillBeSaidOnce : @[
     @{ OneOfTheseWillBeSaidOnce : @[@"TURN ON ALL LIGHTS", @"TURN OFF ALL LIGHTS"] },
     @{ ThisWillBeSaidOnce : @[
     @{ OneOfTheseWillBeSaidOnce : @[@"TURN LIGHT ON AT", @"TURN LIGHT OFF AT"] },
     @{ OneOfTheseWillBeSaidOnce : @[@"FIRST FLOOR", @"SECOND FLOOR", @"THIRD FLOOR", @"FOURTH FLOOR"] } ]
     } ]
     } ]
     };
     */
    
    
    /*
     app_id`: `135431`
     `key`: `138289ba194ec1862b00`
     `channel`: `homekit_channel`
     `secret`: `dd5ffaacb91264be3264`
     
     all_off
     all_on
     
     floor1_on
     floor1_off
     */
    
    _recognizedCommands =                @{
                                           ThisWillBeSaidOnce : @[ @{ ThisWillBeSaidOnce : @[@"HEY IRIS"] },
                                                                   @{ OneOfTheseWillBeSaidOnce : @[
                                                                              @{ OneOfTheseWillBeSaidOnce : @[@"TURN ON ALL LIGHTS", @"TURN OFF ALL LIGHTS"] },
                                                                              @{ ThisWillBeSaidOnce : @[
                                                                                         @{ OneOfTheseWillBeSaidOnce : @[@"TURN LIGHT ON AT", @"TURN LIGHT OFF AT"] },
                                                                                         @{ OneOfTheseWillBeSaidOnce : @[@"FIRST FLOOR", @"SECOND FLOOR", @"THIRD FLOOR", @"FOURTH FLOOR"] } ]
                                                                                 } ]
                                                                      } ]
                                           };
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        
        if (granted == true) {
            NSError *error = [_languageModelGenerator generateGrammarFromDictionary:_recognizedCommands
                                                                     withFilesNamed:kFileName
                                                             forAcousticModelAtPath:[OEAcousticModel
                                                                                     pathToModel:kAcousticModel]];
            
            if (error == nil) {
                _languageModelPath  = [_languageModelGenerator pathToSuccessfullyGeneratedGrammarWithRequestedName:kFileName];
                _dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:kFileName];
                
                [[OEPocketsphinxController sharedInstance] setActive:YES error:nil];
                [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:_languageModelPath
                                                                                dictionaryAtPath:_dictionaryPath
                                                                             acousticModelAtPath:[OEAcousticModel
                                                                                                  pathToModel:kAcousticModel]
                                                                             languageModelIsJSGF:YES];
                
                [_micControlButton setTitle:@"Listening.." forState:UIControlStateNormal];
                [_micControlButton setBackgroundColor:[UIColor greenColor]];
                [_micControlButton setUserInteractionEnabled:YES];
            } else {
                NSLog(@"Error: %@", [error localizedDescription]);
                [_micControlButton setUserInteractionEnabled:NO];
                [_recognizedText setText:[NSString stringWithFormat:@"There was an error, here is the description: %@", [error localizedDescription]]];
            }
        } else {
            [_micControlButton setUserInteractionEnabled:NO];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"IMPORTANT!" message:@"Please open the microphone permisson in the settings." delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil, nil];
            [alertView show];
        }
        
    }];
}

- (void)createUI {
    _micControlButton = [[UIButton alloc] initForAutoLayout];
    [_micControlButton setTitle:@"Listen" forState:UIControlStateNormal];
    [_micControlButton setBackgroundColor:[UIColor redColor]];
    [[_micControlButton layer] setCornerRadius:7.5];
    [_micControlButton addTarget:self action:@selector(didTapMicButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_micControlButton];
    
    [_micControlButton autoSetDimension:ALDimensionHeight toSize:50];
    [_micControlButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(30, 50, 50, 50) excludingEdge:ALEdgeBottom];
    
    
    _recognizedText = [[UILabel alloc] initForAutoLayout];
    [_recognizedText setNumberOfLines:0];
    [_recognizedText setText:@"Your Speech will come here when the IRIS understand the correct commands.."];
    [_recognizedText setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:_recognizedText];
    
    CGFloat minumunHeight = 25.0;
    [_recognizedText autoSetDimension:ALDimensionHeight toSize:minumunHeight relation:NSLayoutRelationGreaterThanOrEqual];
    [_recognizedText autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:30.0];
    [_recognizedText autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:30.0];
    [_recognizedText autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_micControlButton withOffset:30.0];
    
    
    _recognizableText = [[UILabel alloc] initForAutoLayout];
    [_recognizableText setNumberOfLines:0];
    [_recognizableText setText:@"LIGHTS COMMANDS:\n\t1) HEY IRIS\n\t2.1)TURN ON/OFF ALL LIGHTS\n\t2.2)TURN LIGHT ON/OFF AT FIRST/SECOND FLOOR"];
    [_recognizableText setTextAlignment:NSTextAlignmentLeft];
    [self.view addSubview:_recognizableText];
    
    [_recognizableText autoSetDimension:ALDimensionHeight toSize:minumunHeight relation:NSLayoutRelationGreaterThanOrEqual];
    [_recognizableText autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:30.0];
    [_recognizableText autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:30.0];
    [_recognizableText autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_recognizedText withOffset:30.0];
}

#pragma mark - String to MD5 Converter

- (NSString *)md5:(NSString*)_password {
    const char *cStr = [_password UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

#pragma mark - Request Method

- (void)sendRequest: (NSString *)event {
    NSString *app_id = [NSString stringWithFormat:@"%d", 135431];
    
    NSString *timeInterval = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
    
    NSDictionary *parameters = @{
                                 @"name": event,
                                 @"data": @"{\"name\": \"John\",\"message\": \"Hello\"}",
                                 @"channel": @"homekit_channel"
                                 };
    
    NSData *parametersData = [NSJSONSerialization dataWithJSONObject:parameters
                                                             options:0
                                                               error:nil];
    
    NSString *parametersJSON = [[NSString alloc] initWithData:parametersData encoding:NSUTF8StringEncoding];
    
    
    NSString *parametersMD5 = [self md5:parametersJSON];
    
    NSDictionary *authParameters = @{
                                     @"auth_key": @"138289ba194ec1862b00",
                                     @"auth_timestamp": timeInterval,
                                     @"auth_version": @"1.0",
                                     @"body_md5": parametersMD5
                                     };
    
    NSString *HMAC_SHA_256 = [NSString stringWithFormat:@"POST\n/apps/%@/events\nauth_key=%@&auth_timestamp=%@&auth_version=1.0&body_md5=%@", app_id, authParameters[@"auth_key"], authParameters[@"auth_timestamp"], parametersMD5];
    
    NSString *secret = @"dd5ffaacb91264be3264";
    
    NSString *result = [NSString hmac:HMAC_SHA_256 withKey:secret];
    
    NSString *postURL = [@"http://api.pusherapp.com" stringByAppendingString:[NSString stringWithFormat:@"/apps/%@/events?auth_key=%@&auth_timestamp=%@&auth_version=1.0&body_md5=%@&auth_signature=%@", app_id, authParameters[@"auth_key"], authParameters[@"auth_timestamp"], parametersMD5, result]];
    
    
    _requestOperationManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [_requestOperationManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    _requestOperationManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [_requestOperationManager.responseSerializer setAcceptableContentTypes:[NSSet setWithObject:@"text/html"]];
    
    [_requestOperationManager POST:postURL parameters:parameters success:^(AFHTTPRequestOperation *operation, id respondObject) {
        NSLog(@"success!");
        if ([_on_off isEqualToString:@"on"]) {
            if ([_floorNumberString isEqualToString:@"all"]) {
                [_fliteController say:[NSString stringWithFormat:@"Turning on %@ lights", _floorNumberString] withVoice:_slt];
            } else {
                [_fliteController say:[NSString stringWithFormat:@"Turning light on at %@ floor", _floorNumberString] withVoice:_slt];
            }
        } else {
            if ([_floorNumberString isEqualToString:@"all"]) {
                [_fliteController say:[NSString stringWithFormat:@"Turning off %@ lights", _floorNumberString] withVoice:_slt];
            } else {
                [_fliteController say:[NSString stringWithFormat:@"Turning light off at %@ floor", _floorNumberString] withVoice:_slt];
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark - Button Actions

- (void)didTapMicButton:(UIButton *)button {
    
    UIColor *buttonBackgroundColor = nil;
    NSString *buttonTitle = nil;
    
    if (_micControlButton.backgroundColor == [UIColor greenColor]) {
        buttonBackgroundColor = [UIColor redColor];
        buttonTitle = @"Listen";
        [[OEPocketsphinxController sharedInstance] suspendRecognition];
    } else {
        buttonBackgroundColor = [UIColor greenColor];
        buttonTitle = @"Listening...";
        [[OEPocketsphinxController sharedInstance] resumeRecognition];
    }
    
    [_micControlButton setBackgroundColor:buttonBackgroundColor];
    [_micControlButton setTitle:buttonTitle forState:UIControlStateNormal];
}

#pragma mark - OEEventsObserver Delegate

- (void)pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
    
    NSArray *commandWords = [hypothesis componentsSeparatedByString: @" "];
    
    NSString *event = nil;
    
    switch (commandWords.count) {
        case 6: {
            _on_off = commandWords[3];
            _on_off = [_on_off lowercaseString];
            
            _floorNumberString = @"all";
            
            event = [NSString stringWithFormat:@"%@_%@",[_floorNumberString lowercaseString],_on_off];
            break;
        }
        case 8:
            _on_off = commandWords[4];
            _on_off = [_on_off lowercaseString];
            
            _floorNumberString = commandWords[commandWords.count - 2];
            NSInteger floorNumber = 0;
            
            
            if ([_floorNumberString isEqualToString:@"FIRST"]) {
                floorNumber = 1;
                event = [NSString stringWithFormat:@"floor%ld_%@",(long)floorNumber,_on_off];
                
            } else if ([_floorNumberString isEqualToString:@"SECOND"]) {
                floorNumber = 2;
                event = [NSString stringWithFormat:@"floor%ld_%@",(long)floorNumber,_on_off];
                
            } else if ([_floorNumberString isEqualToString:@"THIRD"]) {
                floorNumber = 3;
                event = [NSString stringWithFormat:@"floor%ld_%@",(long)floorNumber,_on_off];
                
            } else if ([_floorNumberString isEqualToString:@"FOURTH"]) {
                floorNumber = 4;
                event = [NSString stringWithFormat:@"floor%ld_%@",(long)floorNumber,_on_off];
                
            }
            break;
        default:
            break;
    }
    
    if (![_on_off isEqualToString:@""] && ![_floorNumberString isEqualToString:@""]) {
        [self sendRequest:event];
        [_recognizedText setText:hypothesis];
    } else {
        [_recognizedText setText:[NSString stringWithFormat:@"Can't send request to the arduino!\n%@",hypothesis]];
    }
}

- (void)pocketsphinxDidReceiveNBestHypothesisArray:(NSArray *)hypothesisArray {
    NSLog(@"The received hypothesis array is: %@", hypothesisArray);
}

- (void)pocketsphinxDidStartListening {
    NSLog(@"Pocketsphinx is now listening.");
}

- (void)pocketsphinxDidDetectSpeech {
    NSLog(@"Pocketsphinx has detected speech.");
}

- (void)pocketsphinxDidDetectFinishedSpeech {
    NSLog(@"Pocketsphinx has detected a period of silence, concluding an utterance.");
}

- (void)pocketsphinxDidStopListening {
    NSLog(@"Pocketsphinx has stopped listening.");
}

- (void)pocketsphinxDidSuspendRecognition {
    NSLog(@"Pocketsphinx has suspended recognition.");
}

- (void)pocketsphinxDidResumeRecognition {
    NSLog(@"Pocketsphinx has resumed recognition.");
}

- (void)pocketSphinxContinuousSetupDidFailWithReason:(NSString *)reasonForFailure {
    NSLog(@"Listening setup wasn't successful and returned the failure reason: %@", reasonForFailure);
}

- (void)pocketSphinxContinuousTeardownDidFailWithReason:(NSString *)reasonForFailure {
    NSLog(@"Listening teardown wasn't successful and returned the failure reason: %@", reasonForFailure);
}

- (void)micPermissionCheckCompleted:(BOOL)result {
    if (result == true) {
        
    } else {
        
    }
}

@end
