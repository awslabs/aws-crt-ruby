#include <ruby.h>

struct my_malloc {
  size_t size;
  void *ptr;
};

static void
my_malloc_free(void *p) {
  struct my_malloc *ptr = p;

  if (ptr->size > 0)
    free(ptr->ptr);
}

static VALUE
my_malloc_alloc(VALUE klass) {
  VALUE obj;
  struct my_malloc *ptr;

  obj = Data_Make_Struct(klass, struct my_malloc, NULL, my_malloc_free, ptr);

  ptr->size = 0;
  ptr->ptr  = NULL;

  return obj;
}

static VALUE
my_malloc_init(VALUE self, VALUE size) {
  struct my_malloc *ptr;
  size_t requested = NUM2SIZET(size);

  if (0 == requested)
    rb_raise(rb_eArgError, "unable to allocate 0 bytes");

  Data_Get_Struct(self, struct my_malloc, ptr);

  ptr->ptr = malloc(requested);

  if (NULL == ptr->ptr)
    rb_raise(rb_eNoMemError, "unable to allocate %ld bytes", requested);

  ptr->size = requested;

  return self;
}

static VALUE
my_malloc_release(VALUE self) {
  struct my_malloc *ptr;

  Data_Get_Struct(self, struct my_malloc, ptr);

  if (0 == ptr->size)
    return self;

  printf("Hello free world!\n");
  ptr->size = 0;
  free(ptr->ptr);

  return self;
}

void
Init_aws_crt_ruby(void) {
  VALUE cMyMalloc;

  cMyMalloc = rb_const_get(rb_cObject, rb_intern("AwsCrtRuby"));

  rb_define_alloc_func(cMyMalloc, my_malloc_alloc);
  rb_define_method(cMyMalloc, "initialize", my_malloc_init, 1);
  rb_define_method(cMyMalloc, "free", my_malloc_release, 0);
}