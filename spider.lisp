(require 'asdf)
(asdf:operate 'asdf:load-op 'trivial-http)
(asdf:operate 'asdf:load-op 'cl-ppcre)

; Crawl the Hype Machine for links to blog posts.
; Crawls using search terms if provided, else crawls what's popular.
; Crawls each blog post for links to MP3 files. 
; Creates a directory for each blog post, stores a link to the post, 
; and downloads and stores the MP3 files in the directory.

; Crawls the hype machine to find blog posts.
(defun crawl-hype (terms)
  (scan-html-for-links 
    (concatenate 'string "http://hype.non-standard.net/" 
      (if (null terms) "popular" terms))
    "<a.*href=\"(http[\S]*)\".*>read post<\/a>"
    #'crawl-blog))

; Crawls a blog post, saves link and MP3 files to disk.
; Don't leave files lying around, they may get in the way of directory creation.
(defun crawl-blog (u)
  (format t "Scanning ~A " u))
  (with-open-file (out (ensure-directories-exist (uri_to_dirname u)) :direction :output)
    

; Only works if the regex payload is in the first capturing group!
; If regex payload is relative it is made absolute using the # parameter URL.
; Takes a block and invokes for each regex match.
(defun scan-html-for-links (u rx fn)
  (cl-ppcre:do-register-groups (link) 
                               (rx (http-get-body u)) 
                               (fn (prefix-link link u))))
     
; Determine whether the first parameter URL is relative, and in that case make 
; it absolute using the scheme and domain from the first parameter URL.
(defun prefix-link (relative absolute)
  (if (null (search "http://" u))
      (cl-ppcre:do-register-groups (prefix) 
                                   ("http:\/\/[^\/]*" absolute) 
                                   (concatenate 'string prefix relative))
      relative))

; Send HTTP GET request for parameter URL and return the response body string.
(defun http-get-body (u)
  (destructuring-bind (code headers body-stream) (trivial-http:http-get u)
    (let ((body (if (assoc :content-length headers)
                    (make-string (parse-integer (cdr (assoc :content-length headers))))
                    (make-string (* 200 1024)))))
      (read-sequence body body-stream) 
      body)))
