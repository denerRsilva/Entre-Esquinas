/* Embedded rules engine. Only game sources supplied by the host are evaluated. */
#include "gdextension_interface.h"
#include "quickjs.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

static GDExtensionInterfaceGetProcAddress lookup;
static GDExtensionClassLibraryPtr library;
static JSRuntime *runtime;
static JSContext *context;
#define GD(type, name) ((GDExtensionInterface##type)lookup(name))
typedef union { void *align; uint8_t data[16]; } GodotValue;
static GodotValue class_name, parent_name, method_name, empty_name, empty_string;
static void name_init(GodotValue *n, const char *s) {
    GD(StringNameNewWithUtf8Chars,"string_name_new_with_utf8_chars")(n,s);
}
static void drop(GDExtensionVariantType type, GodotValue *v) {
    GD(VariantGetPtrDestructor,"variant_get_ptr_destructor")(type)(v);
}
static void evaluate(void *ud, GDExtensionClassInstancePtr self,
        const GDExtensionConstVariantPtr *args, GDExtensionInt count,
        GDExtensionVariantPtr result, GDExtensionCallError *error) {
    if(count != 1 || GD(VariantGetType,"variant_get_type")(args[0])!=GDEXTENSION_VARIANT_TYPE_STRING) {
        error->error=GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT; return;
    }
    GodotValue input,output;
    GD(GetVariantToTypeConstructor,"get_variant_to_type_constructor")(GDEXTENSION_VARIANT_TYPE_STRING)(&input,(void*)args[0]);
    GDExtensionInterfaceStringToUtf8Chars utf8=GD(StringToUtf8Chars,"string_to_utf8_chars");
    size_t len=(size_t)utf8(&input,NULL,0);
    char *src=malloc(len+1);
    utf8(&input,src,len); src[len]=0;
    JSValue v;
    if(strcmp(src,"@nova-sessao")==0) {
        JS_FreeContext(context);
        JS_FreeRuntime(runtime);
        runtime=JS_NewRuntime();
        JS_SetMaxStackSize(runtime,2097152);
        context=JS_NewContext(runtime);
        v=JS_UNDEFINED;
    } else {
        v=JS_Eval(context,src,len,"entre-esquinas",JS_EVAL_TYPE_GLOBAL);
    }
    free(src); drop(GDEXTENSION_VARIANT_TYPE_STRING,&input);
    if(JS_IsException(v)){
        JSValue exc=JS_GetException(context);
        const char *msg=JS_ToCString(context,exc);
        JSValue stack=JS_GetPropertyStr(context,exc,"stack");
        const char *trace=JS_ToCString(context,stack);
        fprintf(stderr,"Entre Esquinas JS: %s\n%s\n",msg?msg:"?",trace?trace:"");
        JS_FreeCString(context,trace); JS_FreeValue(context,stack);
        GD(StringNewWithUtf8Chars,"string_new_with_utf8_chars")(&output,msg?msg:"Erro na simulação");
        JS_FreeCString(context,msg); JS_FreeValue(context,exc);
    } else {
        const char *r=JS_ToCString(context,v);
        GD(StringNewWithUtf8Chars,"string_new_with_utf8_chars")(&output,r?r:"");
        JS_FreeCString(context,r);
    }
    JS_FreeValue(context,v);
    GD(GetVariantFromTypeConstructor,"get_variant_from_type_constructor")(GDEXTENSION_VARIANT_TYPE_STRING)(result,&output);
    drop(GDEXTENSION_VARIANT_TYPE_STRING,&output); error->error=GDEXTENSION_CALL_OK;
}
static void start(void *ud,GDExtensionInitializationLevel level) {
    if(level!=GDEXTENSION_INITIALIZATION_SCENE)return;
    runtime=JS_NewRuntime(); JS_SetMaxStackSize(runtime,2097152); context=JS_NewContext(runtime);
    name_init(&class_name,"RestauranteVM"); name_init(&parent_name,"Object"); name_init(&method_name,"executar"); name_init(&empty_name,"");
    GD(StringNewWithUtf8Chars,"string_new_with_utf8_chars")(&empty_string,"");
    GDExtensionClassCreationInfo4 info={0}; info.is_abstract=1; info.is_exposed=1;
    GD(ClassdbRegisterExtensionClass4,"classdb_register_extension_class4")(library,&class_name,&parent_name,&info);
    GDExtensionPropertyInfo ret={0}; ret.type=GDEXTENSION_VARIANT_TYPE_STRING;ret.name=&empty_name;ret.class_name=&empty_name;ret.hint_string=&empty_string;ret.usage=6;
    GDExtensionClassMethodInfo m={0};m.name=&method_name;m.method_flags=GDEXTENSION_METHOD_FLAG_VARARG|GDEXTENSION_METHOD_FLAG_STATIC|GDEXTENSION_METHOD_FLAG_NORMAL;
    m.call_func=evaluate;m.has_return_value=1;m.return_value_info=&ret;
    GD(ClassdbRegisterExtensionClassMethod,"classdb_register_extension_class_method")(library,&class_name,&m);
}
static void stop(void *ud,GDExtensionInitializationLevel level){
    if(level!=GDEXTENSION_INITIALIZATION_SCENE)return;
    GD(ClassdbUnregisterExtensionClass,"classdb_unregister_extension_class")(library,&class_name);
    drop(GDEXTENSION_VARIANT_TYPE_STRING,&empty_string);
    drop(GDEXTENSION_VARIANT_TYPE_STRING_NAME,&method_name);drop(GDEXTENSION_VARIANT_TYPE_STRING_NAME,&class_name);
    drop(GDEXTENSION_VARIANT_TYPE_STRING_NAME,&parent_name);drop(GDEXTENSION_VARIANT_TYPE_STRING_NAME,&empty_name);
    JS_FreeContext(context); JS_FreeRuntime(runtime);
}
#ifdef _WIN32
__declspec(dllexport)
#else
__attribute__((visibility("default")))
#endif
GDExtensionBool restaurante_init(GDExtensionInterfaceGetProcAddress p,GDExtensionClassLibraryPtr lib,GDExtensionInitialization *init){
    lookup=p;library=lib;init->minimum_initialization_level=GDEXTENSION_INITIALIZATION_SCENE;
    init->initialize=start;init->deinitialize=stop;return 1;
}
