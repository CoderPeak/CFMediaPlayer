//
//  CFHomeViewController.m
//  CFMediaPlayer
//
//  Created by Peak on 17/3/7.
//  Copyright © 2017年 Peak. All rights reserved.
//

#import "CFHomeViewController.h"
#import "CFLivePlayerViewController.h"

@interface CFHomeViewController ()

@end

@implementation CFHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"首页";
    
    UILabel *titleL = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, self.view.cf_width, 50)];
    titleL.numberOfLines = 0;
    titleL.textAlignment = NSTextAlignmentCenter;
    titleL.textColor = CFRandomColor;
    titleL.text = @"交流QQ 545486205\n个人github网址:https://github.com/CoderPeak";
    [self.view addSubview:titleL];
    
    
    
    UIButton *btn0 = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn0 setTitle:@"点此进入--> 直播播放 界面 >>>" forState:UIControlStateNormal];
    [btn0 addTarget:self action:@selector(toVC0) forControlEvents:UIControlEventTouchUpInside];
    btn0.frame = CGRectMake(0, 180, self.view.cf_width, 50);
    [btn0 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn0.backgroundColor = CFRandomColor;
    [self.view addSubview:btn0];

}


- (void)toVC0
{
    CFLivePlayerViewController *vc = [[CFLivePlayerViewController alloc] init];
    
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
