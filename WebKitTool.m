#import <Foundation/Foundation.h>
#import "DDCommandLineInterface.h"
#import "WebKitToolController.h"

int main (int argc, const char * argv[])
{
    return DDCliAppRunWithClass([WebKitToolController class]);
}
