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


static NSString * const IRISPusherAppIdentifier = @"<YOUR PUSHER APP ID>";
static NSString * const IRISPusherAppAuthKey = @"<YOUR PUSHER AUTH KEY>";


@interface IRISRootViewController () <OEEventsObserverDelegate>

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *micImageView;
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UIView *commandLabelsView;
@property (nonatomic, strong) UILabel *irisLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UILabel *firstCommandLabel;
@property (nonatomic, strong) UILabel *secondCommandLabel;
@property (nonatomic, strong) UIView *irisContentView;
@property (nonatomic, strong) UIImageView *irisImageView;
@property (nonatomic, strong) UIButton *stateButton;
@property (nonatomic, strong) UIView *popUpView;
@property (nonatomic, strong) UILabel *popUpLabel;
@property (nonatomic, strong) NSLayoutConstraint *popUpConstraint;

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
    
    _recognizedCommands =   @{ThisWillBeSaidOnce : @[ @{ ThisWillBeSaidOnce : @[@"HEY IRIS"] },
                                                      @{ OneOfTheseWillBeSaidOnce : @[
                                                                 @{ OneOfTheseWillBeSaidOnce : @[@"TURN ON ALL LIGHTS",
                                                                                                 @"TURN OFF ALL LIGHTS"] },

                                                                 @{ ThisWillBeSaidOnce : @[
                                                                            @{ OneOfTheseWillBeSaidOnce : @[@"TURN LIGHTS ON AT",
                                                                                                            @"TURN LIGHTS OFF AT"] },

                                                                            @{ OneOfTheseWillBeSaidOnce : @[@"FIRST FLOOR",
                                                                                                            @"SECOND FLOOR",
                                                                                                            @"THIRD FLOOR",
                                                                                                            @"FOURTH FLOOR"] } ]
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
                
                NSDictionary *stateAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:18.f],
                                                   NSForegroundColorAttributeName: [UIColor colorWithRed:54.0/255.0
                                                                                                   green:213.0/255.0
                                                                                                    blue:180.0/255.0
                                                                                                   alpha:1.0]
                                                   };
                
                NSAttributedString *stateButtonAttributedText = [[NSAttributedString alloc]
                                                                 initWithString:@"Yeah I'm Listening"
                                                                 attributes:stateAttributes];
                
                [_stateButton setAttributedTitle:stateButtonAttributedText forState:UIControlStateNormal];
                [_micImageView setImage:[UIImage imageNamed:@"mic-acik"]];
                [_irisImageView setImage:[UIImage imageNamed:@"iris-on"]];
                [_irisLabel setTextColor:[UIColor colorWithRed:5.0/255.0 green:5.0/255.0 blue:5.0/255.0 alpha:1.0]];
                [_arrowImageView setImage:[UIImage imageNamed:@"arrow-siyah"]];
                [_firstCommandLabel setTextColor:[UIColor colorWithRed:5.0/255.0 green:5.0/255.0 blue:5.0/255.0 alpha:1.0]];
                [_secondCommandLabel setTextColor:[UIColor colorWithRed:5.0/255.0 green:5.0/255.0 blue:5.0/255.0 alpha:1.0]];
                
            } else {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"IMPORTANT!"
                                                                message:@"Please turn on microphone permissons in Settings."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
            
            [alertView show];
        }
    }];
}

#pragma mark - UI Component Creation

- (void)createUI {
    [self.view setClipsToBounds:NO];
    
    CGRect mainFrame = [[UIScreen mainScreen] bounds];
    
    _headerView = [[UIView alloc] initForAutoLayout];
    
    [self.view addSubview:_headerView];

    [_headerView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [_headerView autoSetDimension:ALDimensionHeight toSize:80.f];
    
    
    _micImageView = [[UIImageView alloc] initForAutoLayout];
    
    [_micImageView setImage:[UIImage imageNamed:@"mic"]];
    [_micImageView setContentMode:UIViewContentModeScaleAspectFit];
    [_headerView addSubview:_micImageView];
    
    [_micImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(30, 20, 20, 0) excludingEdge:ALEdgeRight];
    
    
    _headerLabel = [[UILabel alloc] initForAutoLayout];
    
    NSDictionary *headerAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:16.f],
                                        NSForegroundColorAttributeName: [UIColor colorWithRed:185.0/255.0
                                                                                        green:185.0/255.0
                                                                                         blue:185.0/255.0
                                                                                        alpha:1.0]
                                        };
    
    NSAttributedString *headerLabelAttributedText = [[NSAttributedString alloc]
                                                     initWithString:@"List of Comments"
                                                     attributes:headerAttributes];
    
    [_headerLabel setAttributedText:headerLabelAttributedText];
    [_headerLabel setTextAlignment:NSTextAlignmentCenter];
    [_headerLabel sizeToFit];
    
    [_headerView addSubview:_headerLabel];
    
    [_headerLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(37.5, 30, 0, 30) excludingEdge:ALEdgeBottom];
    [_headerLabel autoSetDimension:ALDimensionHeight toSize:25.f relation:NSLayoutRelationGreaterThanOrEqual];
    
    
    UIImageView *lineImageView = [[UIImageView alloc] initForAutoLayout];
    
    [lineImageView setImage:[UIImage imageNamed:@"line"]];
    [lineImageView setContentMode:UIViewContentModeScaleAspectFill];
    
    [_headerView addSubview:lineImageView];
    
    [lineImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 10, 0, 10) excludingEdge:ALEdgeTop];
    
    
    _commandLabelsView = [[UIView alloc] initForAutoLayout];
    
    [self.view addSubview:_commandLabelsView];
    
    [_commandLabelsView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_headerView withOffset:20.f relation:NSLayoutRelationEqual];
    [_commandLabelsView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.view withOffset:0 relation:NSLayoutRelationEqual];
    [_commandLabelsView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.view withOffset:0 relation:NSLayoutRelationEqual];
    [_commandLabelsView autoSetDimension:ALDimensionHeight toSize:(mainFrame.size.height * 0.85) / 2];
    
    
    CGFloat offset = ((mainFrame.size.height * 0.85) / 2) / 7;
    
    NSDictionary *commandAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:18.f],
                                         NSForegroundColorAttributeName: [UIColor colorWithRed:185.0/255.0
                                                                                         green:185.0/255.0
                                                                                          blue:185.0/255.0
                                                                                         alpha:1.0]
                                         };
    
    
    _irisLabel = [[UILabel alloc] initForAutoLayout];
    
    NSAttributedString *irisLabelAttributedText = [[NSAttributedString alloc]
                                                   initWithString:@"Hey Iris"
                                                   attributes:commandAttributes];
    
    [_irisLabel setAttributedText:irisLabelAttributedText];
    [_irisLabel setTextAlignment:NSTextAlignmentCenter];
    [_irisLabel sizeToFit];
    
    [_commandLabelsView addSubview:_irisLabel];
    
    [_irisLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(offset, 0, 0, 0) excludingEdge:ALEdgeBottom];
    
    
    _stateButton = [[UIButton alloc] initForAutoLayout];
    
    NSDictionary *stateAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:18.f],
                                       NSForegroundColorAttributeName: [UIColor colorWithRed:208.0/255.0
                                                                                       green:34.0/255.0
                                                                                        blue:57.0/255.0
                                                                                       alpha:1.0]
                                       };
    
    NSAttributedString *stateButtonAttributedText = [[NSAttributedString alloc]
                                                     initWithString:@"Listen"
                                                     attributes:stateAttributes];
    
    [_stateButton setAttributedTitle:stateButtonAttributedText forState:UIControlStateNormal];
    [_stateButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [_stateButton addTarget:self action:@selector(didTapListenButton:) forControlEvents:UIControlEventTouchUpInside];
    [_stateButton sizeToFit];
    
    [self.view addSubview:_stateButton];
    
    [_stateButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [_stateButton autoSetDimension:ALDimensionHeight toSize:78.f];
    
    
    _arrowImageView = [[UIImageView alloc] initForAutoLayout];

    [_arrowImageView setImage:[UIImage imageNamed:@"arrow-gri"]];
    [_arrowImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [_commandLabelsView addSubview:_arrowImageView];
    
    [_arrowImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_irisLabel withOffset:offset];
    [_arrowImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    
    _firstCommandLabel = [[UILabel alloc] initForAutoLayout];
    
    NSAttributedString *firstCommandLabelAttributedText = [[NSAttributedString alloc]
                                                           initWithString:@"Turn On/Off all lights"
                                                           attributes:commandAttributes];
    
    [_firstCommandLabel setAttributedText:firstCommandLabelAttributedText];
    [_firstCommandLabel setTextAlignment:NSTextAlignmentCenter];
    [_firstCommandLabel sizeToFit];
    
    [_commandLabelsView addSubview:_firstCommandLabel];
    
    [_firstCommandLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_arrowImageView withOffset:offset];
    [_firstCommandLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    
    _secondCommandLabel = [[UILabel alloc] initForAutoLayout];
    
    NSAttributedString *secondCommandLabelAttributedText = [[NSAttributedString alloc]
                                                            initWithString:@"Turn lights On/Off at # floor"
                                                            attributes:commandAttributes];
    
    [_secondCommandLabel setAttributedText:secondCommandLabelAttributedText];
    [_secondCommandLabel setTextAlignment:NSTextAlignmentCenter];
    [_secondCommandLabel sizeToFit];
    
    [_commandLabelsView addSubview:_secondCommandLabel];
    
    [_secondCommandLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_firstCommandLabel withOffset:offset];
    [_secondCommandLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    
    _irisContentView = [[UIView alloc] initForAutoLayout];
    
    [_irisContentView setBackgroundColor:[UIColor clearColor]];
    
    [self.view addSubview:_irisContentView];
    
    [_irisContentView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.view];
    [_irisContentView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.view];
    [_irisContentView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_stateButton];
    [_irisContentView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_commandLabelsView];
    
    
    _irisImageView = [[UIImageView alloc] initForAutoLayout];
    
    [_irisImageView setImage:[UIImage imageNamed:@"iris-off"]];
    [_irisImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [_irisContentView addSubview:_irisImageView];
    
    [_irisImageView autoSetDimensionsToSize:CGSizeMake(52, 98)];
    [_irisImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_irisImageView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    
    
    _popUpView = [[UIView alloc] initForAutoLayout];
    
    [_popUpView setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"popup"]]];

    [self.view addSubview:_popUpView];
    
    [_popUpView autoSetDimensionsToSize:CGSizeMake(mainFrame.size.width, 78)];
    [_popUpView autoAlignAxis:ALAxisVertical toSameAxisOfView:_irisContentView];
    
    _popUpConstraint = [_popUpView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.view];
    
    [self.view bringSubviewToFront:_popUpView];
    
    
    _popUpLabel = [[UILabel alloc] initForAutoLayout];
    
    [_popUpLabel sizeToFit];
    [_popUpView addSubview:_popUpLabel];
    
    [_popUpLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [_popUpLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
}

#pragma mark - Popup Information

- (void)popUpwithInformation:(NSString *)information {
    NSDictionary *infoAttributes = @{
                                     NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:18.f],
                                     NSForegroundColorAttributeName: [UIColor blackColor]
                                     };
    
    NSAttributedString *informationAttributedString = [[NSAttributedString alloc]
                                                       initWithString:information
                                                       attributes:infoAttributes];
    
    [_popUpLabel setAttributedText:informationAttributedString];
    [_popUpLabel sizeToFit];
    [_popUpView layoutIfNeeded];

    _popUpConstraint.constant = -78.f;

    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [_popUpView layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         _popUpConstraint.constant = 0.f;
                         
                         [UIView animateWithDuration:0.5
                                               delay:1.5
                                             options:UIViewAnimationOptionCurveEaseInOut
                                          animations:^{
                                              [_popUpView layoutIfNeeded];
                                          } completion:nil];
                     }];
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
    NSString *timeInterval = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
    
    NSDictionary *parameters = @{
                                 @"name": event,
                                 @"data": @"{}",
                                 @"channel": @"homekit_channel"
                                 };
    
    NSData *parametersData = [NSJSONSerialization dataWithJSONObject:parameters
                                                             options:0
                                                               error:nil];
    
    NSString *parametersJSON = [[NSString alloc] initWithData:parametersData encoding:NSUTF8StringEncoding];
    
    
    NSString *parametersMD5 = [self md5:parametersJSON];
    
    NSDictionary *authParameters = @{
                                     @"auth_key": IRISPusherAppAuthKey,
                                     @"auth_timestamp": timeInterval,
                                     @"auth_version": @"1.0",
                                     @"body_md5": parametersMD5
                                     };
    
    NSString *HMAC_SHA_256 = [NSString stringWithFormat:@"POST\n/apps/%@/events\nauth_key=%@&auth_timestamp=%@&auth_version=1.0&body_md5=%@",
                              IRISPusherAppIdentifier,
                              authParameters[@"auth_key"],
                              authParameters[@"auth_timestamp"],
                              parametersMD5];
    
    NSString *secret = @"dd5ffaacb91264be3264";
    NSString *result = [NSString hmac:HMAC_SHA_256 withKey:secret];
    NSString *postURL = [@"http://api.pusherapp.com" stringByAppendingString:
                         [NSString stringWithFormat:@"/apps/%@/events?auth_key=%@&auth_timestamp=%@&auth_version=1.0&body_md5=%@&auth_signature=%@",
                          IRISPusherAppIdentifier,
                          authParameters[@"auth_key"],
                          authParameters[@"auth_timestamp"],
                          parametersMD5,
                          result]];
    
    _requestOperationManager.requestSerializer = [AFJSONRequestSerializer serializer];

    [_requestOperationManager.requestSerializer setValue:@"application/json"
                                      forHTTPHeaderField:@"Content-Type"];
    
    _requestOperationManager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [_requestOperationManager.responseSerializer setAcceptableContentTypes:[NSSet setWithObject:@"text/html"]];
    
    [_requestOperationManager POST:postURL parameters:parameters success:^(AFHTTPRequestOperation *operation, id respondObject) {
        NSLog(@"Success!");
        if ([_on_off isEqualToString:@"on"]) {
            if ([_floorNumberString isEqualToString:@"all"]) {
                [self popUpwithInformation:@"All lights are on"];
            } else {
                [self popUpwithInformation:[NSString stringWithFormat:@"%@ floor lights are on", [_floorNumberString capitalizedString]]];
            }
        } else {
            if ([_floorNumberString isEqualToString:@"all"]) {
                [self popUpwithInformation:@"All lights are off"];

            } else {
                [self popUpwithInformation:[NSString stringWithFormat:@"%@ floor lights are off", [_floorNumberString capitalizedString]]];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [self popUpwithInformation:@"Network Error"];
    }];
}

#pragma mark - Button Actions

- (void)didTapListenButton:(UIButton *)button {
    NSDictionary *stateAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:18.f],
                                       NSForegroundColorAttributeName: [UIColor colorWithRed:54.0/255.0
                                                                                       green:213.0/255.0
                                                                                        blue:180.0/255.0
                                                                                       alpha:1.0]
                                       };
    
    if ([_stateButton.titleLabel.text isEqualToString:@"Listen"]) {
        [[OEPocketsphinxController sharedInstance] resumeRecognition];
        
        NSAttributedString *stateButtonAttributedText = [[NSAttributedString alloc]
                                                         initWithString:@"Yeah I'm Listening"
                                                         attributes:stateAttributes];
        
        [_stateButton setAttributedTitle:stateButtonAttributedText forState:UIControlStateNormal];
        [_micImageView setImage:[UIImage imageNamed:@"mic-acik"]];
        [_irisImageView setImage:[UIImage imageNamed:@"iris-on"]];
        [_irisLabel setTextColor:[UIColor colorWithRed:5.0/255.0 green:5.0/255.0 blue:5.0/255.0 alpha:1.0]];
        [_arrowImageView setImage:[UIImage imageNamed:@"arrow-siyah"]];
        [_firstCommandLabel setTextColor:[UIColor colorWithRed:5.0/255.0 green:5.0/255.0 blue:5.0/255.0 alpha:1.0]];
        [_secondCommandLabel setTextColor:[UIColor colorWithRed:5.0/255.0 green:5.0/255.0 blue:5.0/255.0 alpha:1.0]];
    } else {
        [[OEPocketsphinxController sharedInstance] suspendRecognition];
        
        NSAttributedString *stateButtonAttributedText = [[NSAttributedString alloc]
                                                         initWithString:@"Listen"
                                                         attributes:stateAttributes];
        
        [_stateButton setAttributedTitle:stateButtonAttributedText forState:UIControlStateNormal];
        [_micImageView setImage:[UIImage imageNamed:@"mic"]];
        [_irisImageView setImage:[UIImage imageNamed:@"iris-off"]];
        [_irisLabel setTextColor:[UIColor colorWithRed:185.0/255.0 green:185.0/255.0 blue:185.0/255.0 alpha:1.0]];
        [_arrowImageView setImage:[UIImage imageNamed:@"arrow-gri"]];
        [_firstCommandLabel setTextColor:[UIColor colorWithRed:185.0/255.0 green:185.0/255.0 blue:185.0/255.0 alpha:1.0]];
        [_secondCommandLabel setTextColor:[UIColor colorWithRed:185.0/255.0 green:185.0/255.0 blue:185.0/255.0 alpha:1.0]];
    }
}

#pragma mark - OEEventsObserver Delegate

- (void)pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis
                        recognitionScore:(NSString *)recognitionScore
                             utteranceID:(NSString *)utteranceID {

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
