(defconst A//hello-world
  `((define main
      (push "Hello, World!\n")
      :loop
        (& jempt :ret)
        (write)
        (goto :loop)
      :ret
        (ret))
    :_start
      (call main)))
