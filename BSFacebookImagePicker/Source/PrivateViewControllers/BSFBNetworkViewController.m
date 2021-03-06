/*
 * Copyright 2013 Brad Smith
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "BSFBNetworkViewController.h"

@implementation BSFBNetworkViewController

@synthesize delegate, navigationController, items;

- (id)init {
  if (self = [super initWithStyle:UITableViewStylePlain]) {
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.backgroundColor = [UIColor whiteColor];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadFromNetwork) name:@"USER_DID_LOGIN" object:nil];
}


-(void)showLoadingView {
  if (!_loadingView) {
      _loadingView = [[BSFBLoadingView alloc] initWithFrame:self.view.bounds];
  }
  self.tableView.scrollEnabled = NO;
  [self.view addSubview:_loadingView];
}


-(void)hideLoadingView {
  [_loadingView removeFromSuperview];
  self.tableView.scrollEnabled = YES;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

-(void) viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:NO animated:animated];
}


-(void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if ([[BSFacebook sharedInstance] isSessionValid]) {
    if (self.items.count < 1) {
      [self loadFromNetwork];
    }
  }
}

-(void) showEmptyView {
  self.tableView.scrollEnabled = NO;
  if (!_emptyView) {
    _emptyView = [[BSFBEmptyView alloc] initWithFrame:self.view.bounds];
  }
  [self.view addSubview:_emptyView];
}

-(void) loadFromNetwork {
  [self showLoadingView];
  
  NSURL *url = self.url;
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                      success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                        NSArray *data = JSON[@"data"];
                                                                                        self.nextURL = JSON[@"paging"][@"next"];
                                                                                        
                                                                                        self.items = [[NSMutableArray alloc] initWithArray:data];
                                                                                        [self hideLoadingView];
                                                                                        [self.tableView reloadData];
                                                                                        
                                                                                        if (self.nextURL) {
                                                                                          [self loadMoreFromNetwork];
                                                                                        }
                                                                                        if (self.items.count < 1) {
                                                                                          [self showEmptyView];
                                                                                        }
                                                                                      } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
                                                                                        if ([response statusCode] == 400 && JSON[@"error"] != nil) {
                                                                                          [self hideLoadingView];
                                                                                          [self.navigationController popToRootViewControllerAnimated:YES];
                                                                                          [[BSFacebook sharedInstance] logout];
                                                                                          [[NSNotificationCenter defaultCenter] postNotificationName:@"USER_DID_LOGOUT" object:nil];
                                                                                        }
                                                                                        NSLog(@"Error Loading From Network: %@",[error localizedDescription]);
                                                                                      }];
  [operation start];
}

-(void) loadMoreFromNetwork {
  
}

-(void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(NSURL *) url {
  NSString *token = [[BSFacebook sharedInstance] accessToken];
  return [NSURL URLWithString:[NSString stringWithFormat:@"%@&access_token=%@", [_url absoluteString],token] ];
}

@end
