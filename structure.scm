(library (melt structure)
  (export type-parser
          type-post
          type-renderer
          type-page

		  type-site
		  type-asset

		  type-hook
		  type-trigger
		  type-chain
		  type-data

		  type-command)
  
  (import (scheme))
  
  ;; it now is an uniform utility! can be stroed in
  ;; one place and use multiple times!
  (module type-parser
          [make-parser
		   parser?
		   parser-type
		   parser-proc
		   parser-refp]
          (define-record-type
              parser
            (nongenerative melt-parser)
            (fields
			 ;; the symbol which means the file type
			 ;; the symbol is used as file extension
			 (immutable type parser-type)
			 ;; proc is the procedure which take charge with
			 ;; the source file
             (immutable proc parser-proc)
			 ;; refp==>refine procedure : update the resource file
			 ;; it need to be designed carefully, because it will alter
			 ;; the source file
			 (immutable refp parser-refp))))

  ;; there maybe a lot of procedure between
  ;; this two components.
  
  ;; the post recieve the data from parser
  ;; and then process the data to satisfy its
  ;; need. So the data stored in a post is all
  ;; the data one post needs. No more change but
  ;; use.

  ;; the meta and attr is all an assoc list
  (module type-post
          [make-post
		   post?
		   post-meta post-meta-set!
		   post-attr post-attr-set!
		   post-cont post-cont-set!]
          (define-record-type
              post
            (nongenerative melt-post)
            (fields
			 ;; it contains the attribute about the
			 ;; source file!
			 ;; the meta and attr are all the data
			 ;; but cont is sxml tree
             (mutable meta post-meta post-meta-set!)
             (mutable attr post-attr post-attr-set!)
             (mutable cont post-cont post-cont-set!))))

  ;; used to render the page component
  (module type-renderer
		  [make-renderer
		   renderer?
		   renderer-type
		   renderer-proc proc-set!
		   renderer-data data-set!]
		  (define-record-type
			  renderer
			(nongenerative melt-renderer)
			(fields
			 ;; the type is an unique id to distinguish the render
			 (immutable type renderer-type)
			 ;; proc==>process process function used to render the
			 ;; page
			 (mutable proc renderer-proc proc-set!)
			 ;; data is the data which maybe be needed, it's the data type.
			 (mutable data renderer-data data-set!))))
  
  ;; page is used to compose one page
  ;; and use the proc to write ti to disk
  ;; all the information relevant should
  ;; be done before page, page only store
  ;; information about the page it self.
  (module type-page
          [make-page
		   page?
		   page-meta page-meta-set!
		   page-cont page-cont-set!
		   page-comt page-comt-set!]
          (define-record-type
              page
            (nongenerative melt-page)
            (fields
			 ;; meta ==> store some useful value for the page
			 ;; cont ==> is the template for the page; actually it
			 ;; is a procedure accept itself a page obj, and generate
			 ;; sxml tree
			 ;; comt ==> it is a list of symbols map the renderer type
			 ;; need to be registered first
             (mutable meta page-meta page-meta-set!)
			 (mutable cont page-cont page-cont-set!)
			 (mutable comt page-comt page-comt-set!))))

  ;; site type is only for definition
  (module type-site
          [make-site
		   site?
		   site-layout layout-set!
		   site-comt comt-set!
		   site-attr attr-set!]
          (define-record-type
              site
            (nongenerative melt-site)
            (fields
			 ;; it stores data type data
			 ;; this defines how the published site to be generated!
			 (mutable layout site-layout layout-set!)
			 ;; comt==>component : it describes the composement of the
			 ;; site and the action on each component. for example: the site map
			 ;; it's also a data type
			 (mutable comt site-comt comt-set!)
             ;; it is the attribute of the site like domain name
			 ;; it is a data type
			 (mutable attr site-attr attr-set!))))
  
  (module type-asset
          [make-asset
		   asset?
           asset-source
           asset-target]
          (define-record-type
              asset
            (nongenerative melt-asset)
            (fields
             (immutable source asset-source)
             (immutable target asset-target))))
  
  ;; hook is the small data cell or execute cell
  (module type-hook
          [make-hook
		   hook?
		   hook-name
		   hook-type
		   hook-proc-arg proc-arg-set!
		   hook-data hook-data-set!]
          (define-record-type
              hook
            (nongenerative melt-hook)
            (fields
			 ;; hook's name
             (immutable name hook-name)
             ;; if the type is 'data, proc-arg contain data
             ;; else if the type is 'proc, proc-arg is defined as following
             (immutable type hook-type)
             ;; proc-arg is a dot pair
             ;; (procedure . args)
             ;; the hook function
             ;; the arguments, it must be wrapped in a list
             (mutable proc-arg hook-proc-arg proc-arg-set!)
             ;; it sotres hook data, it must be type data
             (mutable data hook-data hook-data-set!))))

  ;; the trigger module for future
  (module type-trigger
		  [make-trigger
		   trigger?
		   trigger-cond
		   trigger-act]
		  (define-record-type
			  trigger
			(nongenerative melt-trigger)
			(fields
			 (immutable cond trigger-cond)
			 (immutable act  trigger-act))))

  
  ;; define the execution priority and data transform
  (module type-chain
          [make-chain
		   chain?
		   chain-condition condition-set!
		   chain-execution execution-set!
		   chain-data chain-data-set!]
          (define-record-type
              chain
            (nongenerative melt-chain)
            (fields
             ;; condition must be #t or #f
             ;; or a procedure which return #t
             ;; or #f and accept no argument
             (mutable condition chain-condition condition-set!)
             ;; it is a list of procedure without arguments
             (mutable execution chain-execution execution-set!)
			 ;; data type
             (mutable data chain-data chain-data-set!))))

  (module type-data
		  [make-data
		   data?
		   data-keys data-keys-set!
		   data-cont data-cont-set!]
		  (define-record-type
			  data
			(nongenerative melt-data)
			(fields
			 ;; a list of symbols
			 (mutable keys data-keys data-keys-set!)
			 ;; an assoc list which contains keys in the
			 ;; keys field
			 (mutable cont data-cont data-cont-set!))))

  (module type-command
		  [make-command
		   command?
		   command-name
		   command-desc
		   command-proc]
		  (define-record-type
			  command
			(nongenerative melt-command)
			(fields
			 ;; symbol, which specifics string in command line
			 (immutable name command-name)
			 ;; string, one line description
			 (immutable description command-desc)
			 ;; procedure for the command, accept arguments
			 (immutable procedure command-proc))))
  
  )
