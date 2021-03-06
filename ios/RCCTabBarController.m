#import "RCCTabBarController.h"
#import "RCCViewController.h"
#import <React/RCTConvert.h>
#import "RCCManager.h"
#import "RCTHelpers.h"
#import <React/RCTUIManager.h>
#import "UIViewController+Rotation.h"
#import "RCCNavigationController.h"

static const int kTabBarHeight = 51;

@interface RCTUIManager ()

- (void)configureNextLayoutAnimation:(NSDictionary *)config
                        withCallback:(RCTResponseSenderBlock)callback
                       errorCallback:(__unused RCTResponseSenderBlock)errorCallback;

@end

@interface RCCTabBarController () <UITabBarDelegate>

@property(nonatomic, strong) UIView *holder;
@property(nonatomic, strong) UITabBar *tabBar;
@property(nullable, nonatomic,copy) NSArray<__kindof UIViewController *> *viewControllers;
@property(nullable, nonatomic, assign) __kindof UIViewController *selectedViewController; // This may return the "More" navigation controller if it exists.

@property (nonatomic, strong) NSLayoutConstraint *tabBarHeightConstraint;
@property (nonatomic, strong) NSNumber *tabBarHeight;

@end

@implementation RCCTabBarController

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return [self supportedControllerOrientations];
}

- (BOOL)shouldSelectViewController:(UIViewController *)viewController shouldSendJsEvent:(BOOL)shouldSendJsEvent {
  dispatch_queue_t queue = [[RCCManager sharedInstance].getBridge uiManager].methodQueue;
  dispatch_async(queue, ^{
    [[[RCCManager sharedInstance].getBridge uiManager] configureNextLayoutAnimation:nil withCallback:^(NSArray* arr){} errorCallback:^(NSArray* arr){}];
  });
  
  if (self.selectedIndex != [self.viewControllers indexOfObject:viewController] && shouldSendJsEvent) {
    NSDictionary *body = @{
                           @"selectedTabIndex": @([self.viewControllers indexOfObject:viewController]),
                           @"unselectedTabIndex": @(self.selectedIndex)
                           };
    [RCCTabBarController sendScreenTabChangedEvent:viewController body:body];
    
    [[[RCCManager sharedInstance] getBridge].eventDispatcher sendAppEventWithName:@"bottomTabSelected" body:body];
  } else {
    [RCCTabBarController sendScreenTabPressedEvent:viewController body:nil];
  }
  
  return YES;
}

- (UIImage *)image:(UIImage*)image withColor:(UIColor *)color1
{
  UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextTranslateCTM(context, 0, image.size.height);
  CGContextScaleCTM(context, 1.0, -1.0f);
  CGContextSetBlendMode(context, kCGBlendModeNormal);
  CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
  CGContextClipToMask(context, rect, image.CGImage);
  [color1 setFill];
  CGContextFillRect(context, rect);
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}

- (instancetype)initWithProps:(NSDictionary *)props children:(NSArray *)children globalProps:(NSDictionary*)globalProps bridge:(RCTBridge *)bridge
{
  self = [super init];
  if (!self) return nil;

  UIView *holder = [[UIView alloc] init];
  self.holder = holder;
  holder.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:holder];

  UIView *tabBarHolder = [[UIView alloc] init];
  tabBarHolder.translatesAutoresizingMaskIntoConstraints = NO;
  tabBarHolder.layer.shadowRadius = 14;
  tabBarHolder.layer.shadowOpacity = 0.08;
  tabBarHolder.layer.shadowColor = [UIColor blackColor].CGColor;
  tabBarHolder.layer.shadowOffset = CGSizeZero;
  [self.view addSubview:tabBarHolder];

  UITabBar *tabBar = [[UITabBar alloc] init];
  self.tabBar = tabBar;
  tabBar.translatesAutoresizingMaskIntoConstraints = NO;
  tabBar.delegate = self;
  [tabBarHolder addSubview:tabBar];

  NSDictionary *views = @{
          @"view" : self.view,
          @"holder" : holder,
		  @"tabBarHolder" : tabBarHolder,
          @"tabBar" : tabBar,
  };

  NSDictionary *tabsStyle = props[@"style"];

  NSMutableDictionary *metrics = @{}.mutableCopy;

  NSString *verticalFormat;
  metrics[@"tabBarHeight"] = @(kTabBarHeight);
  verticalFormat = @"V:|[tabBar]|";

  [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[tabBar]-0-|" options:nil metrics:metrics views:views]];
  [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:verticalFormat options:nil metrics:metrics views:views]];

  [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[holder]-0-|" options:nil metrics:metrics views:views]];
  [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[tabBarHolder]-0-|" options:nil metrics:metrics views:views]];
  [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[holder]-0-[tabBarHolder]-0-|" options:nil metrics:metrics views:views]];

  self.tabBar.translucent = YES; // default
  self.tabBar.shadowImage = [[UIImage alloc] init];
  self.tabBar.backgroundImage = [[UIImage alloc] init];

  UIColor *buttonColor = nil;
  UIColor *labelColor = nil;
  UIColor *selectedLabelColor = nil;

  if (tabsStyle)
  {
    NSString *tabBarButtonColor = tabsStyle[@"tabBarButtonColor"];
    if (tabBarButtonColor)
    {
      UIColor *color = tabBarButtonColor != (id)[NSNull null] ? [RCTConvert UIColor:tabBarButtonColor] : nil;
      self.tabBar.tintColor = color;
      buttonColor = color;
    }
    NSString *tabBarSelectedButtonColor = tabsStyle[@"tabBarSelectedButtonColor"];
    if (tabBarSelectedButtonColor)
    {
      UIColor *color = tabBarSelectedButtonColor != (id)[NSNull null] ? [RCTConvert UIColor:tabBarSelectedButtonColor] : nil;
      self.tabBar.tintColor = color;
    }
    NSString *tabBarLabelColor = tabsStyle[@"tabBarLabelColor"];
    if(tabBarLabelColor) {
      UIColor *color = tabBarLabelColor != (id)[NSNull null] ? [RCTConvert UIColor:tabBarLabelColor] : nil;
      labelColor = color;
    }
    NSString *tabBarSelectedLabelColor = tabsStyle[@"tabBarSelectedLabelColor"];
    if(tabBarLabelColor) {
      UIColor *color = tabBarSelectedLabelColor != (id)[NSNull null] ? [RCTConvert UIColor:
                                                                        tabBarSelectedLabelColor] : nil;
      selectedLabelColor = color;
    }
    NSString *tabBarBackgroundColor = tabsStyle[@"tabBarBackgroundColor"];
    if (tabBarBackgroundColor)
    {
      UIColor *color = tabBarBackgroundColor != (id)[NSNull null] ? [RCTConvert UIColor:tabBarBackgroundColor] : nil;
      self.tabBar.barTintColor = color;
    }

    NSString *tabBarTranslucent = tabsStyle[@"tabBarTranslucent"];
    if (tabBarTranslucent)
    {
      self.tabBar.translucent = [tabBarTranslucent boolValue];
    }

    if (!self.tabBarHeightConstraint) {
      self.tabBarHeightConstraint = [NSLayoutConstraint constraintWithItem:tabBarHolder attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
      [NSLayoutConstraint activateConstraints:@[self.tabBarHeightConstraint]];
    }
    self.tabBarHeightConstraint.constant = self.tabBarHeight.floatValue;
  }
  
  NSMutableArray *viewControllers = [NSMutableArray array];
  NSMutableArray *tabBarItems = [NSMutableArray array];
  NSMutableArray *tabBarScreenIDs = [NSMutableArray array];

  // go over all the tab bar items
  for (NSDictionary *tabItemLayout in children)
  {
    BOOL hasTab = [tabItemLayout[@"type"] isEqualToString:@"TabBarControllerIOS.Item"];

    // make sure the layout is valid
    if (!tabItemLayout[@"props"]) continue;
    
    // get the view controller inside
    if (!tabItemLayout[@"children"]) continue;
    if (![tabItemLayout[@"children"] isKindOfClass:[NSArray class]]) continue;
    UIViewController *viewController;
    if (hasTab)
    {
      if ([tabItemLayout[@"children"] count] < 1) continue;
      NSDictionary *childLayout = tabItemLayout[@"children"][0];
      viewController = [RCCViewController controllerWithLayout:childLayout globalProps:globalProps bridge:bridge];
      [tabBarScreenIDs addObject:tabItemLayout[@"props"][@"screen"]];
    } else {
      NSUInteger index = [tabBarScreenIDs indexOfObject:tabItemLayout[@"props"][@"component"]];
      if (index == NSNotFound) {
        NSDictionary *childLayout = tabItemLayout;
        viewController = [RCCViewController controllerWithLayout:childLayout globalProps:globalProps bridge:bridge];
      } else {
        viewController = viewControllers[index];
      }
    }
    if (!viewController) continue;

    if (hasTab)
    {
      // create the tab icon and title
      NSString *title = tabItemLayout[@"props"][@"title"];
		if ([title isEqualToString:@""]) title = nil;

      UIImage *iconImage = nil;
      id icon = tabItemLayout[@"props"][@"icon"];
      if (icon)
      {
        iconImage = [RCTConvert UIImage:icon];
        if (buttonColor)
        {
          iconImage = [[self image:iconImage withColor:buttonColor] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        }
      }
      UIImage *iconImageSelected = nil;
      id selectedIcon = tabItemLayout[@"props"][@"selectedIcon"];
      if (selectedIcon)
      {
        iconImageSelected = [RCTConvert UIImage:selectedIcon];
      }
      else
      {
        iconImageSelected = [RCTConvert UIImage:icon];
      }
		if (!title) {
			iconImageSelected = nil;
		}

      UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:iconImage tag:0];
      tabBarItem.accessibilityIdentifier = tabItemLayout[@"props"][@"testID"];
      tabBarItem.selectedImage = iconImageSelected;

	  tabBarItem.imageInsets = UIEdgeInsetsMake(title ? -1 : 2, 0, title ? 1 : -2, 0);

	  NSMutableDictionary *unselectedAttributes = [RCTHelpers textAttributesFromDictionary:tabsStyle withPrefix:@"tabBarText" baseFont:[UIFont systemFontOfSize:10]];
      if (!unselectedAttributes[NSForegroundColorAttributeName] && labelColor)
      {
        unselectedAttributes[NSForegroundColorAttributeName] = labelColor;
      }

      [tabBarItem setTitleTextAttributes:unselectedAttributes forState:UIControlStateNormal];

      NSMutableDictionary *selectedAttributes = [RCTHelpers textAttributesFromDictionary:tabsStyle withPrefix:@"tabBarSelectedText" baseFont:[UIFont systemFontOfSize:10]];
      if (!selectedAttributes[NSForegroundColorAttributeName] && selectedLabelColor && title)
      {
        selectedAttributes[NSForegroundColorAttributeName] = selectedLabelColor;
      }

      [tabBarItem setTitleTextAttributes:selectedAttributes forState:UIControlStateSelected];
	  [tabBarItem setTitlePositionAdjustment:UIOffsetMake(0, -3)];

      [tabBarItems addObject:tabBarItem];
    }

    [viewControllers addObject:viewController];
  }

  self.tabBar.items = tabBarItems.copy;

  // replace the tabs
  self.viewControllers = viewControllers.copy;

  [self setRotation:props];
  
  return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

	if (self.holder.subviews.count == 0) {
    RCCNavigationController *navigationController = self.viewControllers.lastObject;
    NSString *moduleName = ((RCTRootView *)navigationController.viewControllers.firstObject.view).moduleName;
	__block NSUInteger index = self.viewControllers.count - 1;
    if (![moduleName isEqualToString:@""]) {
		[self.viewControllers enumerateObjectsUsingBlock:^(__kindof UINavigationController *obj, NSUInteger idx, BOOL *stop)
		{
			NSString *tabModuleName = ((RCTRootView *)obj.viewControllers.firstObject.view).moduleName;
			if ([tabModuleName isEqualToString:moduleName]) {
				index = idx;
				*stop = YES;
			}
		}];
	}

    [self setSelectedIndex:index];
  }
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];

	if (!self.tabBarHeight)
	{
		CGFloat extraInset = 0;
        if ([self.view respondsToSelector:@selector(safeAreaInsets)]) {
            extraInset = self.view.safeAreaInsets.bottom;
        }
		self.tabBarHeight = @(kTabBarHeight + extraInset);
		self.tabBarHeightConstraint.constant = self.tabBarHeight.floatValue;
	}
}

- (void)performAction:(NSString*)performAction actionParams:(NSDictionary*)actionParams bridge:(RCTBridge *)bridge completion:(void (^)(void))completion
{
  if ([performAction isEqualToString:@"switchTo"])
  {
    UIViewController *viewController = nil;
    NSNumber *tabIndex = actionParams[@"tabIndex"];
    if (tabIndex)
    {
      [self setSelectedIndex:tabIndex.unsignedIntegerValue];
      return;
    }

    NSString *contentId = actionParams[@"contentId"];
    NSString *contentType = actionParams[@"contentType"];
    if (contentId && contentType)
    {
      viewController = [[RCCManager sharedInstance] getControllerWithId:contentId componentType:contentType];
    }
    
    if (viewController)
    {
      [self setSelectedViewController:viewController shouldSendJsEvent:NO];
    }
  }
  
  if ([performAction isEqualToString:@"setTabButton"])
  {
    UIViewController *viewController = nil;
    UITabBarItem *tabBarItem = nil;
    NSNumber *tabIndex = actionParams[@"tabIndex"];
    if (tabIndex)
    {
      NSUInteger i = [tabIndex unsignedIntegerValue];
      
      if ([self.viewControllers count] > i)
      {
        viewController = self.viewControllers[i];
      }
      if ([self.tabBar.items count] > i)
      {
        tabBarItem = self.tabBar.items[i];
      }
    }
    NSString *contentId = actionParams[@"contentId"];
    NSString *contentType = actionParams[@"contentType"];
    if (contentId && contentType)
    {
      viewController = [[RCCManager sharedInstance] getControllerWithId:contentId componentType:contentType];
    }
    
    if (viewController && tabBarItem)
    {
      UIImage *iconImage = nil;
      id icon = actionParams[@"icon"];
      if (icon && icon != (id)[NSNull null])
      {
        iconImage = [RCTConvert UIImage:icon];
        iconImage = [[self image:iconImage withColor:self.tabBar.tintColor] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        viewController.tabBarItem.image = iconImage;
        tabBarItem.image = iconImage;
      }
      UIImage *iconImageSelected = nil;
      id selectedIcon = actionParams[@"selectedIcon"];
      if (selectedIcon && selectedIcon != (id)[NSNull null])
      {
        iconImageSelected = [RCTConvert UIImage:selectedIcon];
        viewController.tabBarItem.selectedImage = iconImageSelected;
        tabBarItem.selectedImage = iconImage;
      }
      NSString *label = actionParams[@"label"];
      if (label) {
        tabBarItem.title = label;
      }
    }
  }
  
  if ([performAction isEqualToString:@"setTabBarHidden"])
  {
    BOOL hidden = [actionParams[@"hidden"] boolValue];

	  self.tabBarHeightConstraint.constant = hidden ? 0 : self.tabBarHeight.floatValue;
	  self.tabBar.clipsToBounds = hidden;

    [UIView animateWithDuration: ([actionParams[@"animated"] boolValue] ? 0.45 : 0)
                          delay: 0
         usingSpringWithDamping: 0.75
          initialSpringVelocity: 0
                        options: (hidden ? UIViewAnimationOptionCurveEaseIn : UIViewAnimationOptionCurveEaseOut)
                     animations:^()
     {
		 [self.view setNeedsLayout];
		 [self.view layoutIfNeeded];
     }
                     completion:^(BOOL finished)
     {
       if (completion != nil)
       {
         completion();
       }
     }];
    return;
  }
  else if (completion != nil)
  {
    completion();
  }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
  [self setSelectedIndex:selectedIndex shouldSendJsEvent:NO];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex shouldSendJsEvent:(BOOL)shouldSendJsEvent
{
  [self setSelectedViewController:self.viewControllers[selectedIndex] shouldSendJsEvent:shouldSendJsEvent];

  _selectedIndex = selectedIndex;

  if (selectedIndex < self.tabBar.items.count) {
    [self.tabBar setSelectedItem:self.tabBar.items[selectedIndex]];
  } else {
    [self.tabBar setSelectedItem:nil];
  }
}

-(void)setSelectedViewController:(__kindof UIViewController *)selectedViewController shouldSendJsEvent:(BOOL)shouldSendJsEvent
{
  UIViewController *oldController = _selectedViewController;

  _selectedViewController = selectedViewController;

    [self shouldSelectViewController:selectedViewController shouldSendJsEvent:shouldSendJsEvent];

  if (![oldController isEqual:selectedViewController])
  {
    selectedViewController.view.frame = oldController.view.bounds;
    [self addChildViewController:selectedViewController];
    [oldController willMoveToParentViewController:nil];
    selectedViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.holder addSubview:selectedViewController.view];
    [selectedViewController didMoveToParentViewController:self];
    [oldController removeFromParentViewController];
    [oldController.view removeFromSuperview];

    NSDictionary *views = @{@"view" : selectedViewController.view};
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|" options:nil metrics:nil views:views]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|" options:nil metrics:nil views:views]];
  }
}

- (UIViewController *)selectedViewController {
  return self.viewControllers[self.selectedIndex];
}

+(void)sendScreenTabChangedEvent:(UIViewController*)viewController body:(NSDictionary*)body{
  [RCCTabBarController sendTabEvent:@"bottomTabSelected" controller:viewController body:body];
}

+(void)sendScreenTabPressedEvent:(UIViewController*)viewController body:(NSDictionary*)body{
  [RCCTabBarController sendTabEvent:@"bottomTabReselected" controller:viewController body:body];
}

+(void)sendTabEvent:(NSString *)event controller:(UIViewController*)viewController body:(NSDictionary*)body{
  if ([viewController.view isKindOfClass:[RCTRootView class]]){
    RCTRootView *rootView = (RCTRootView *)viewController.view;
    
    if (rootView.appProperties && rootView.appProperties[@"navigatorEventID"]) {
      NSString *navigatorID = rootView.appProperties[@"navigatorID"];
      NSString *screenInstanceID = rootView.appProperties[@"screenInstanceID"];
      
      
      NSMutableDictionary *screenDict = [NSMutableDictionary dictionaryWithDictionary:@
                                         {
                                           @"id": event,
                                           @"navigatorID": navigatorID,
                                           @"screenInstanceID": screenInstanceID
                                         }];
      
      
      if (body) {
        [screenDict addEntriesFromDictionary:body];
      }
      
      [[[RCCManager sharedInstance] getBridge].eventDispatcher sendAppEventWithName:rootView.appProperties[@"navigatorEventID"] body:screenDict];
    }
  }
  
  if ([viewController isKindOfClass:[UINavigationController class]]) {
    UINavigationController *navigationController = (UINavigationController*)viewController;
    UIViewController *topViewController = [navigationController topViewController];
    [RCCTabBarController sendTabEvent:event controller:topViewController body:body];
  }
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
  [self setSelectedIndex:[self.tabBar.items indexOfObject:item] shouldSendJsEvent:YES];
}

- (NSInteger)indexForScreen:(NSString *)screen
{
  __block NSInteger selectedIndex = -1;

  [self.viewControllers enumerateObjectsUsingBlock:^(UINavigationController *navigationController, NSUInteger idx, BOOL *stop)
  {
      RCTRootView *tabView = (RCTRootView *)navigationController.viewControllers.firstObject.view;
      NSString *tabScreen = tabView.moduleName;

      if ([screen isEqualToString:tabScreen]) {
        selectedIndex = idx;
        *stop = YES;
      }
  }];

  return selectedIndex;
}

- (void)showScreenWithLayout:(NSDictionary *)layout props:(NSDictionary *)props
{
  RCTRootView *currentView = (RCTRootView *) self.selectedViewController.childViewControllers.firstObject.view;
  NSString *currentModuleName = currentView.moduleName;

  NSString *newModuleName = layout[@"props"][@"component"];

  if (![currentModuleName isEqualToString:newModuleName]) {

      id controller = [RCCViewController controllerWithLayout:layout globalProps:props bridge:[[RCCManager sharedInstance] getBridge]];
      if (controller == nil) {
          return;
      }

      NSMutableArray *tempControllers = self.viewControllers.mutableCopy;
      [tempControllers removeLastObject];
      [tempControllers addObject:controller];
      self.viewControllers = tempControllers.copy;

      self.selectedIndex = self.tabBar.items.count;
  }
}

@end
