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
//  SOPIAppDelegate.h
//  SOPImobile

#import <UIKit/UIKit.h>
#import "PdAudioController.h"
#import "SOPIperformanceViewController.h"
#import "SOPIsettingViewController.h"


@class SOPIsettingViewController;

@interface SOPIAppDelegate : UIResponder <UIApplicationDelegate,UINavigationControllerDelegate>{
    
}

@property (strong, nonatomic) UIWindow *window;
@property (readonly,strong,nonatomic) CMMotionManager *sharedMotionManager;

@end
