This implements D language support in the GCC back end, and adds
relevant documentation about the GDC front end.
---

diff --git gcc/cgraph.h gcc/cgraph.h
--- gcc/cgraph.h
+++ gcc/cgraph.h
@@ -884,6 +884,7 @@ void fixup_same_cpp_alias_visibility (symtab_node *, symtab_node *target, tree);
 basic_block init_lowered_empty_function (tree, bool);
 void cgraph_reset_node (struct cgraph_node *);
 bool expand_thunk (struct cgraph_node *, bool);
+bool expand_thunk2 (struct cgraph_node *, bool, bool);
 
 /* In cgraphclones.c  */
 
diff --git gcc/cgraphunit.c gcc/cgraphunit.c
--- gcc/cgraphunit.c
+++ gcc/cgraphunit.c
@@ -1454,11 +1454,13 @@ thunk_adjust (gimple_stmt_iterator * bsi,
 }
 
 /* Expand thunk NODE to gimple if possible.
+   When FORCE_GIMPLE_THUNK is true, gimple thunk is created and
+   no assembler is produced.
    When OUTPUT_ASM_THUNK is true, also produce assembler for
    thunks that are not lowered.  */
 
 bool
-expand_thunk (struct cgraph_node *node, bool output_asm_thunks)
+expand_thunk2 (struct cgraph_node *node, bool output_asm_thunks, bool force_gimple_thunk)
 {
   bool this_adjusting = node->thunk.this_adjusting;
   HOST_WIDE_INT fixed_offset = node->thunk.fixed_offset;
@@ -1469,7 +1471,7 @@ expand_thunk (struct cgraph_node *node, bool output_asm_thunks)
   tree a;
 
 
-  if (this_adjusting
+  if (!force_gimple_thunk && this_adjusting
       && targetm.asm_out.can_output_mi_thunk (thunk_fndecl, fixed_offset,
 					      virtual_value, alias))
     {
@@ -1692,6 +1694,15 @@ expand_thunk (struct cgraph_node *node, bool output_asm_thunks)
   return true;
 }
 
+/* Expand thunk NODE to gimple if possible.
+   When OUTPUT_ASM_THUNK is true, also produce assembler for
+   thunks that are not lowered.  */
+bool
+expand_thunk (struct cgraph_node *node, bool output_asm_thunks)
+{
+  return expand_thunk2 (node, output_asm_thunks, false);
+}
+
 /* Assemble thunks and aliases associated to NODE.  */
 
 static void
diff --git gcc/config/darwin.h gcc/config/darwin.h
--- gcc/config/darwin.h
+++ gcc/config/darwin.h
@@ -49,6 +49,10 @@ see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
 /* Suppress g++ attempt to link in the math library automatically. */
 #define MATH_LIBRARY ""
 
+/* Suppress gdc attempt to link in the thread and time library automatically. */
+#define THREAD_LIBRARY ""
+#define TIME_LIBRARY ""
+
 /* We have atexit.  */
 
 #define HAVE_ATEXIT
diff --git gcc/config/i386/cygming.h gcc/config/i386/cygming.h
--- gcc/config/i386/cygming.h
+++ gcc/config/i386/cygming.h
@@ -170,6 +170,10 @@ along with GCC; see the file COPYING3.  If not see
 
 #undef MATH_LIBRARY
 #define MATH_LIBRARY ""
+#undef THREAD_LIBRARY
+#define THREAD_LIBRARY ""
+#undef TIME_LIBRARY
+#define TIME_LIBRARY ""
 
 #undef TARGET_LIBC_HAS_FUNCTION
 #define TARGET_LIBC_HAS_FUNCTION no_c99_libc_has_function
diff --git gcc/config/linux-android.h gcc/config/linux-android.h
--- gcc/config/linux-android.h
+++ gcc/config/linux-android.h
@@ -57,3 +57,9 @@
 
 #define ANDROID_ENDFILE_SPEC \
   "%{shared: crtend_so%O%s;: crtend_android%O%s}"
+
+/* Suppress gdc attempt to link in the thread and time library automatically. */
+#if ANDROID_DEFAULT
+# define THREAD_LIBRARY ""
+# define TIME_LIBRARY ""
+#endif
diff --git gcc/config/rs6000/rs6000.c gcc/config/rs6000/rs6000.c
--- gcc/config/rs6000/rs6000.c
+++ gcc/config/rs6000/rs6000.c
@@ -25077,7 +25077,8 @@ rs6000_output_function_epilogue (FILE *file,
 	 either, so for now use 0.  */
       if (! strcmp (language_string, "GNU C")
 	  || ! strcmp (language_string, "GNU GIMPLE")
-	  || ! strcmp (language_string, "GNU Go"))
+	  || ! strcmp (language_string, "GNU Go")
+	  || ! strcmp (language_string, "GNU D"))
 	i = 0;
       else if (! strcmp (language_string, "GNU F77")
 	       || ! strcmp (language_string, "GNU Fortran"))
diff --git gcc/doc/frontends.texi gcc/doc/frontends.texi
--- gcc/doc/frontends.texi
+++ gcc/doc/frontends.texi
@@ -9,6 +9,7 @@
 @cindex GNU Compiler Collection
 @cindex GNU C Compiler
 @cindex Ada
+@cindex D
 @cindex Fortran
 @cindex Go
 @cindex Java
@@ -17,7 +18,7 @@
 GCC stands for ``GNU Compiler Collection''.  GCC is an integrated
 distribution of compilers for several major programming languages.  These
 languages currently include C, C++, Objective-C, Objective-C++, Java,
-Fortran, Ada, and Go.
+Fortran, Ada, D and Go.
 
 The abbreviation @dfn{GCC} has multiple meanings in common use.  The
 current official meaning is ``GNU Compiler Collection'', which refers
diff --git gcc/doc/install.texi gcc/doc/install.texi
--- gcc/doc/install.texi
+++ gcc/doc/install.texi
@@ -1423,12 +1423,12 @@ their runtime libraries should be built.  For a list of valid values for
 grep language= */config-lang.in
 @end smallexample
 Currently, you can use any of the following:
-@code{all}, @code{ada}, @code{c}, @code{c++}, @code{fortran},
+@code{all}, @code{ada}, @code{c}, @code{c++}, @code{d}, @code{fortran},
 @code{go}, @code{java}, @code{objc}, @code{obj-c++}.
 Building the Ada compiler has special requirements, see below.
 If you do not pass this flag, or specify the option @code{all}, then all
 default languages available in the @file{gcc} sub-tree will be configured.
-Ada, Go and Objective-C++ are not default languages; the rest are.
+Ada, D, Go and Objective-C++ are not default languages; the rest are.
 
 @item --enable-stage1-languages=@var{lang1},@var{lang2},@dots{}
 Specify that a particular subset of compilers and their runtime
diff --git gcc/doc/invoke.texi gcc/doc/invoke.texi
--- gcc/doc/invoke.texi
+++ gcc/doc/invoke.texi
@@ -1213,6 +1213,15 @@ called @dfn{specs}.
 Ada source code file containing a library unit body (a subprogram or
 package body).  Such files are also called @dfn{bodies}.
 
+@item @var{file}.d
+D source code file.
+
+@item @var{file}.di
+D interface code file.
+
+@item @var{file}.dd
+D documentation code file.
+
 @c GCC also knows about some suffixes for languages not yet included:
 @c Pascal:
 @c @var{file}.p
@@ -1248,6 +1257,7 @@ objective-c  objective-c-header  objective-c-cpp-output
 objective-c++ objective-c++-header objective-c++-cpp-output
 assembler  assembler-with-cpp
 ada
+d
 f77  f77-cpp-input f95  f95-cpp-input
 go
 java
diff --git gcc/doc/sourcebuild.texi gcc/doc/sourcebuild.texi
--- gcc/doc/sourcebuild.texi
+++ gcc/doc/sourcebuild.texi
@@ -109,6 +109,9 @@ The Objective-C and Objective-C++ runtime library.
 @item libquadmath
 The runtime support library for quad-precision math operations.
 
+@item libphobos
+The D standard runtime library.
+
 @item libssp
 The Stack protector runtime library.
 
diff --git gcc/doc/standards.texi gcc/doc/standards.texi
--- gcc/doc/standards.texi
+++ gcc/doc/standards.texi
@@ -282,6 +282,16 @@ available online, see @uref{http://gcc.gnu.org/readings.html}
 As of the GCC 4.7.1 release, GCC supports the Go 1 language standard,
 described at @uref{http://golang.org/doc/go1.html}.
 
+@section D language
+
+The D language is under development as of this writing; see the
+@uref{http://dlang.org/@/language-reference.html, current language
+reference}.  At present the current major version of D is 2.0, and
+there is no way to describe the language supported by GCC in terms of
+a specific minor version.  In general GCC follows the D frontend
+releases closely, and any given GCC release will support the current
+language as of the date that the release was frozen.
+
 @section References for other languages
 
 @xref{Top, GNAT Reference Manual, About This Guide, gnat_rm,
diff --git gcc/dwarf2out.c gcc/dwarf2out.c
--- gcc/dwarf2out.c
+++ gcc/dwarf2out.c
@@ -4613,6 +4613,15 @@ is_ada (void)
   return lang == DW_LANG_Ada95 || lang == DW_LANG_Ada83;
 }
 
+/* Return TRUE if the language is D.  */
+static inline bool
+is_dlang (void)
+{
+  unsigned int lang = get_AT_unsigned (comp_unit_die (), DW_AT_language);
+
+  return lang == DW_LANG_D;
+}
+
 /* Remove the specified attribute if present.  */
 
 static void
@@ -19296,6 +19305,8 @@ gen_compile_unit_die (const char *filename)
   language = DW_LANG_C89;
   if (strcmp (language_string, "GNU C++") == 0)
     language = DW_LANG_C_plus_plus;
+  else if (strcmp (language_string, "GNU D") == 0)
+    language = DW_LANG_D;
   else if (strcmp (language_string, "GNU F77") == 0)
     language = DW_LANG_Fortran77;
   else if (strcmp (language_string, "GNU Pascal") == 0)
@@ -20237,7 +20248,7 @@ declare_in_namespace (tree thing, dw_die_ref context_die)
 
   if (ns_context != context_die)
     {
-      if (is_fortran ())
+      if (is_fortran () || is_dlang ())
 	return ns_context;
       if (DECL_P (thing))
 	gen_decl_die (thing, NULL, ns_context);
@@ -20260,7 +20271,7 @@ gen_namespace_die (tree decl, dw_die_ref context_die)
     {
       /* Output a real namespace or module.  */
       context_die = setup_namespace_context (decl, comp_unit_die ());
-      namespace_die = new_die (is_fortran ()
+      namespace_die = new_die (is_fortran () || is_dlang ()
 			       ? DW_TAG_module : DW_TAG_namespace,
 			       context_die, decl);
       /* For Fortran modules defined in different CU don't add src coords.  */
@@ -20317,7 +20328,7 @@ gen_decl_die (tree decl, tree origin, dw_die_ref context_die)
       break;
 
     case CONST_DECL:
-      if (!is_fortran () && !is_ada ())
+      if (!is_fortran () && !is_ada () && !is_dlang ())
 	{
 	  /* The individual enumerators of an enum type get output when we output
 	     the Dwarf representation of the relevant enum type itself.  */
@@ -20787,7 +20798,7 @@ dwarf2out_decl (tree decl)
     case CONST_DECL:
       if (debug_info_level <= DINFO_LEVEL_TERSE)
 	return;
-      if (!is_fortran () && !is_ada ())
+      if (!is_fortran () && !is_ada () && !is_dlang ())
 	return;
       if (TREE_STATIC (decl) && decl_function_context (decl))
 	context_die = lookup_decl_die (DECL_CONTEXT (decl));
diff --git gcc/gcc.c gcc/gcc.c
--- gcc/gcc.c
+++ gcc/gcc.c
@@ -1034,6 +1034,7 @@ static const struct compiler default_compilers[] =
   {".java", "#Java", 0, 0, 0}, {".class", "#Java", 0, 0, 0},
   {".zip", "#Java", 0, 0, 0}, {".jar", "#Java", 0, 0, 0},
   {".go", "#Go", 0, 1, 0},
+  {".d", "#D", 0, 1, 0}, {".dd", "#D", 0, 1, 0}, {".di", "#D", 0, 1, 0},
   /* Next come the entries for C.  */
   {".c", "@c", 0, 0, 1},
   {"@c",
