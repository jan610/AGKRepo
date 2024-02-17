
#import <QuartzCore/QuartzCore.h>

#import "Core.h"
#import "AGKViewController.h"
#include "AGK.h"
#include "interpreter.h"

// define one of these to fix the player to that orientation forever
//#define AGK_LANDSCAPE
//#define AGK_PORTRAIT

using namespace AGK;

BOOL g_bDisplayLinkReady = FALSE;

@interface AGKViewController ()
@property (nonatomic, retain) EAGLContext *context;
@end

@implementation AGKViewController

@synthesize context;

- (void)didReceiveMemoryWarning
{
	// doesn't recognise memory pool?
	//NSLog( @"Received memory warning" );
	//extern NSAutoreleasePool *pool;
	//[pool drain];
	[super didReceiveMemoryWarning];
}

static AGKViewController* sharedViewController;

+ (BOOL)isOpen
{
    return sharedViewController != nil;
}

+ (AGKViewController*)getSharedViewController
{
    @synchronized (self) {
        if ( sharedViewController == nil )
        {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            sharedViewController = [ storyboard instantiateViewControllerWithIdentifier:@"AGKViewController" ];
            [sharedViewController retain];
        }
    }
    return sharedViewController;
}

-(void) awakeFromNib
{
    NSLog( @"AGK view did load" );
    sharedViewController = self;
    
    [ super awakeFromNib ];
    
#ifdef USE_METAL
    CAMetalLayer *metalLayer = (CAMetalLayer*) self.view.layer;
    CGSize drawableSize = self.view.bounds.size;
    UIScreen* screen = self.view.window.screen ?: [UIScreen mainScreen];
    drawableSize.width *= screen.nativeScale;
    drawableSize.height *= screen.nativeScale;
    metalLayer.opaque = TRUE;
    self.view.contentScaleFactor = UIScreen.mainScreen.nativeScale;
#else
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.view.layer;
	eaglLayer.opaque = TRUE;
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
									kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
									nil];
#endif
	
    agk::SetExtraAGKPlayerAssetsMode ( 2 );
	try
	{
#ifdef USE_METAL
		agk::InitGraphics( self, AGK_RENDERER_MODE_ONLY_ADVANCED, 0 );
#else
        agk::InitGraphics( self, AGK_RENDERER_MODE_ONLY_LOWEST, 0 );
#endif
	}
	catch(...)
	{
		uString err; agk::GetLastError(err);
		err.Prepend( "Error: " );
		agk::Message( err.GetStr() );
		PlatformAppQuit();
		return;
	}
		    
	active = FALSE;
    frameInterval = 1;
    displayLink = nil;
    g_bDisplayLinkReady = TRUE;
    
    App.m_iUseFirebase = 0;
    
    try
    {
        App.Begin();
    }
    catch(...)
    {
        uString err; agk::GetLastError(err);
        err.Prepend( "Error: " );
        agk::Message( err.GetStr() );
        PlatformAppQuit();
        return;
    }
    [self setActive];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
#ifdef AGK_LANDSCAPE
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
#else 
    #ifdef AGK_PORTRAIT
        return (interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
    #else
        if ( agk::IsCapturingImage() && ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) )
        {
            return interfaceOrientation == UIInterfaceOrientationPortrait;
        }
        
        switch( interfaceOrientation )
        {
            case UIInterfaceOrientationPortrait: return agk::CanOrientationChange(1) ? YES : NO;
            case UIInterfaceOrientationPortraitUpsideDown: return agk::CanOrientationChange(2) ? YES : NO;
            case UIInterfaceOrientationLandscapeLeft: return agk::CanOrientationChange(4) ? YES : NO;
            case UIInterfaceOrientationLandscapeRight: return agk::CanOrientationChange(3) ? YES : NO;
            default: return NO;
        }
    #endif
#endif
}

-(NSUInteger)supportedInterfaceOrientations
{
#ifdef AGK_LANDSCAPE
    return UIInterfaceOrientationMaskLandscape;
#else
    #ifdef AGK_PORTRAIT
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    #else
        int result = 0;
        if ( agk::CanOrientationChange(1) ) result |= UIInterfaceOrientationMaskPortrait;
        if ( agk::CanOrientationChange(2) ) result |= UIInterfaceOrientationMaskPortraitUpsideDown;
        if ( agk::CanOrientationChange(3) ) result |= UIInterfaceOrientationMaskLandscapeRight;
        if ( agk::CanOrientationChange(4) ) result |= UIInterfaceOrientationMaskLandscapeLeft;
        return result;
    #endif
#endif
}

-(BOOL)shouldAutoRotate
{
    return YES;
}

-(BOOL)prefersHomeIndicatorAutoHidden
{
    // set by SetImmersiveMode
    return agk::GetInternalDataI(0) ? YES : NO;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    //NSLog(@"Orientation Changed");
    agk::UpdatePtr( self );
}

- (BOOL) prefersStatusBarHidden
{
    /*
    if (@available(iOS 11.0, *))
    {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        CGFloat topPadding = window.safeAreaInsets.top;
        if ( topPadding > 0 )
        {
            return agk::GetInternalDataI(0) ? YES : NO;
        }
        else
        {
            return YES;
        }
    }
    else */
    {
        return YES;
    }
}

- (void)dealloc
{
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog( @"AGK View will appear" );
    [self setActive];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog( @"AGK View will disappear" );
    [self setInactive];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    NSLog( @"AGK View did unload" );
	[super viewDidUnload];
}

- (NSInteger)frameInterval
{
    return frameInterval;
}

- (void)setFrameInterval:(NSInteger)interval
{
    /*
	 Frame interval defines how many display frames must pass between each time the display link fires.
	 The display link will only fire 30 times a second when the frame internal is two on a display that refreshes 60 times a second. The default frame interval setting of one will fire 60 times a second when the display refreshes at 60 times a second. A frame interval setting of less than one results in undefined behavior.
	 */
    if (interval >= 1)
    {
        frameInterval = interval;
        
        if (active)
        {
            [self setInactive];
            [self setActive];
        }
    }
}

- (void)setActive
{
	if ( g_bDisplayLinkReady == FALSE )
        return;
	
    if (!active)
    {
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView)];
        [displayLink setFrameInterval:frameInterval];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        active = TRUE;
    }
}

- (void)setInactive
{
    if (active)
    {
        [displayLink invalidate];
        displayLink = nil;
        
        active = FALSE;
    }
}

- (void)drawView
{
    static int has_error = 0;
    if ( has_error ) return;
    if ( !active ) return;
    
    try
	{
        App.Loop();
	}
	catch(...)
	{
		uString err; agk::GetLastError(err);
		err.Prepend( "Error: \n\n" );
		agk::Message( err.GetStr() );
        has_error = 1;
	}
}

@end
