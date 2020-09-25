#import <Security/Security.h>

void* (SecTaskCopyValueForEntitlement)(void* task, CFStringRef entitlement, CFErrorRef  _Nullable *error);
void* (SecTaskCreateFromSelf)(CFAllocatorRef allocator);

static NSString* LLDefaultSecurityApplicationGroupIdentifier(void) {
	void* task = NULL;
	NSString *applicationGroupIdentifier = nil;
	
	do {
		task = SecTaskCreateFromSelf(kCFAllocatorDefault);
		if (task == NULL) {
			break;
		}
		CFTypeRef applicationGroupIdentifiers = SecTaskCopyValueForEntitlement(task, CFSTR("com.apple.security.application-groups"), NULL);
		if (applicationGroupIdentifiers == NULL) {
			break;
		}
		if (CFGetTypeID(applicationGroupIdentifiers) != CFArrayGetTypeID() || CFArrayGetCount(applicationGroupIdentifiers) == 0) {
			CFRelease(applicationGroupIdentifiers);
			break;
		}
		CFTypeRef firstApplicationGroupIdentifier = CFArrayGetValueAtIndex(applicationGroupIdentifiers, 0);
		CFRelease(applicationGroupIdentifiers);
		if (CFGetTypeID(firstApplicationGroupIdentifier) != CFStringGetTypeID()) {
			break;
		}
		applicationGroupIdentifier = CFBridgingRelease(CFRetain(firstApplicationGroupIdentifier));
	} while (0);
	
	if (task != NULL) {
		CFRelease(task);
	}
	return applicationGroupIdentifier;
}

%hook NSUserDefaults
- (id)initWithSuiteName:(NSString *)arg1 {
	if (!arg1 || [arg1 hasPrefix:@"com.apple."]) {
		return %orig(arg1);
	} else {
		return %orig(LLDefaultSecurityApplicationGroupIdentifier());
	}
}
%end

%hook NSFileManager
- (id)containerURLForSecurityApplicationGroupIdentifier:(NSString *)arg1 {
	if (!arg1 || [arg1 hasPrefix:@"com.apple."]) {
		return %orig(arg1);
	} else {
		return %orig(LLDefaultSecurityApplicationGroupIdentifier());
	}
}
%end