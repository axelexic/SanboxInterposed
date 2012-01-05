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


#include <stdio.h>
#include <security/mac.h>


#define DYLD_INTERPOSE(_replacement,_replacee) \
__attribute__((used)) static struct{ const void* replacement; const void* replacee; } _interpose_##_replacee \
__attribute__((section ("__DATA,__interpose"))) = { (const void*)(unsigned long)&_replacement, (const void*)(unsigned long)&_replacee };


int IGNORE__mac_syscall(const char *_policyname, int _call, void *_arg);

/* This should ideally be static, but we keep the symbol exposed so that dlsym
 * can find it the app has been interposed of not. This is better than looping
 * through _dyld_get_image_name() in my opinion.
 */

int IGNORE__mac_syscall(const char *_policyname, int _call, void *_arg){
    fprintf(stdout, "Someone called __mac_syscall with parameters: ('%s', '%d', %p)\n", _policyname, _call, _arg);
    fprintf(stdout, "We are not going to conform to what the program says!\n");
    return 0;
}

DYLD_INTERPOSE(IGNORE__mac_syscall, __mac_syscall);
