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
//  SOPIInfoViewViewController.m
//  SOPImobile
//


#import "SOPIInfoViewController.h"

#define APP_BUILD_REVISION @"$Rev$"
#define APP_BUILD_DATE @"$Date$"
#define APP_LAST_AUTHOR @"$Author$"

@interface SOPIInfoViewController ()

@end

@implementation SOPIInfoViewController
@synthesize versionLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    // Custom initialization
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSString *version=[[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleShortVersionString"];
    versionLabel.text=[NSString stringWithFormat:@"version : %@",version];
}

- (void)viewDidUnload{
    [self setVersionLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)done:(id)sender {
    [[self navigationController] popToRootViewControllerAnimated:YES];
    //[self dismissModalViewControllerAnimated:YES];
}
@end
