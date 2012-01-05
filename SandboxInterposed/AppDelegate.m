/**
 * Copyright (C) 2011 Yogesh Prem Swami.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */


#import <dlfcn.h>
#import <errno.h>
#import "AppDelegate.h"


@implementation AppDelegate

@synthesize pathTextField = _pathTextField;
@synthesize imageToShow = _imageToShow;
@synthesize window = _window;
@synthesize status = _status;

- (void)dealloc
{
    [_status release];
    [super dealloc];
}

-(void) openFile: (NSString*) fileName{
    const char* file = [fileName UTF8String];
    NSString* statusString = nil;
    int fd;
    ssize_t count;
    if ((fd = open(file, O_RDONLY)) < 0 ) {
        statusString = [NSString stringWithFormat:@"Error: %s while opening file: %@.",
                       strerror(errno), [fileName lastPathComponent]];
    }else{
        char buffer[512];
        /* Report success since we are able to open the file. */
        statusString = [NSString stringWithFormat:@"Successfully opened file: %@. File descriptor: %d\n\n",
                       [fileName lastPathComponent], fd];
        count = read(fd, buffer, 511);
        
        if (count < 0) {
            statusString = [statusString stringByAppendingFormat:@"Unable to read. Error: %s", strerror(errno)];
        }else{
            buffer[count] = '\0';
            statusString = [statusString stringByAppendingFormat:@"Contents: %s", buffer];
        }
    }
    
    self.status = statusString;
    
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    void* interposer = NULL;

    /* Check if the interposer is present. */
    interposer = dlsym(RTLD_DEFAULT, "IGNORE__mac_syscall");

    /* this is safe and reasonably efficient. */
    if (interposer != NULL) {
        NSURL* imagePath = [[NSBundle mainBundle] URLForImageResource:@"DeliverySuccess"];
        self.imageToShow.image = [[[NSImage alloc] initWithContentsOfURL:imagePath] autorelease];
    }else{
        NSLog(@"No one's trying to interpose. Good.");
    }
}


- (IBAction)openDocument:(id)sender {

    /* Tyring to open file using open panel. This does not work with
     * interposing since openpanel IPC service is not running under our
     * DYLD_INSERT_LIBRARIES environment. This however is not a win for sandbox!
     */

    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.allowsMultipleSelection = NO;
    openPanel.canChooseDirectories    = NO;
    openPanel.canChooseFiles          = YES;
    openPanel.title = @"Select a file to open!";
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        /* Got the file! */
        if (result == NSFileHandlingPanelOKButton) {
            NSURL* fileURL = [[openPanel URLs] objectAtIndex:0];
            [self openFile: [fileURL path]];
        }else if(result == NSFileHandlingPanelCancelButton){
            self.status = @"Either sanbox deined open panel, or you cancelled selection";
        }else{
            self.status = @"You don't have access to interact with the file system.";
        }
    }];
}

/* The user can select what ever file she wants. With interposing, the sandbox is
 * totally ineffective.
 */
- (IBAction)openDocumentPathDirect:(id)sender {
    NSString* fileName = [self.pathTextField stringValue];
    [self openFile: fileName];
}


@end
