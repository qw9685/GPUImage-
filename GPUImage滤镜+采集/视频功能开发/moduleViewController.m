//
//  moduleViewController.m
//  视频组件功能开发
//
//  Created by mac on 2019/7/17.
//  Copyright © 2019 cc. All rights reserved.
//

#import "moduleViewController.h"
#import "GPUImageViewController.h"

@interface moduleViewController ()<UITableViewDelegate,UITableViewDataSource>

@end

@implementation moduleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initUI];
}

- (void)initUI{
    
    UITableView* tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 5;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString* cellID = @"cell";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:0 reuseIdentifier:cellID];
    }
    
    switch (indexPath.row) {
            case 0:
            cell.textLabel.text = @"采集+美颜";
            break;
            
        default:
            break;
    }
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    switch (indexPath.row) {
            case 0:
            [self.navigationController pushViewController:[GPUImageViewController new] animated:NO];
            break;
            
            
        default:
            break;
    }
}

@end
