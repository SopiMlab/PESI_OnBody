/*
 *
 * Created by: Koray Tahiroğlu, Miguel Valero Espada, Nuno Correia, James Nesfield;
 * Academy of Finland (project 137646) The Notion of Participative and Enacting Sonic Interaction - PESI
 * SOPI research group, Aalto University, School of Arts, Design and Architecture
 *
 * Copyright (c) 2013 Aalto University. All rights reserved. <koray.tahiroglu@aalto.fi>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/SopiMlab/ for documentation
 *
 */

//
//  SOPIViewController.h
//  SOPImobile
//

#import <UIKit/UIKit.h>
#import "PdDispatcher.h"
#import <CoreMotion/CoreMotion.h>

@interface SOPIsettingViewController : UIViewController<UIAccelerometerDelegate>{
    UIAccelerationValue accelerationX;
    UIAccelerationValue accelerationY;
    UIAccelerationValue accelerationZ;
    double gyroscopeX;
    double gyroscopeY;
    double gyroscopeZ;
}
@property (weak, nonatomic) IBOutlet UISlider *updateRateSlider;
@property (weak, nonatomic) IBOutlet UILabel *updateFrequecyLabel;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet UIButton *colourSample;
@property (weak, nonatomic) IBOutlet UISegmentedControl *colourSwitch;
@property (weak, nonatomic) IBOutlet UILabel *IPinfo;
@property (weak, nonatomic) IBOutlet UIProgressView *accelerationBarX;
@property (weak, nonatomic) IBOutlet UIProgressView *accelerationBarY;
@property (weak, nonatomic) IBOutlet UIProgressView *accelerationBarZ;
@property (weak, nonatomic) IBOutlet UIProgressView *gyroscopeBarX;
@property (weak, nonatomic) IBOutlet UIProgressView *gyroscopeBarY;
@property (weak, nonatomic) IBOutlet UIProgressView *gyroscopeBarZ;
@property (weak, nonatomic) IBOutlet UISwitch *accelerometerSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *gyroscopeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *vibrationSwitch;


- (IBAction)infoButton:(id)sender;
- (IBAction)colourSwitch:(id)sender;
- (IBAction)accelerometerSwitch:(id)sender;
- (IBAction)gyroscopeSwitch:(id)sender;
- (IBAction)vibrationSwitch:(id)sender;

- (IBAction)done:(id)sender;

@end
