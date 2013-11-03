#lang racket
(require sdl/sdl/main) ;https://github.com/cosmez/racket-sdl
(require RacketGL/opengl/main) ;https://github.com/stephanh42/RacketGL
(require ffi/vector)

(define *SCREEN_WIDTH* 800)
(define *SCREEN_HEIGHT* 600)
(define *TITLE* "ParticleBench")

(define *MIN_X* -80.0)
(define *MAX_X* 80.0)
(define *MIN_Y* -90.0)
(define *MAX_Y* 50.0)
(define *MIN_DEPTH* 50.0)
(define *MAX_DEPTH* 250.0)

(define *START_RANGE* 15.0)
(define *START_X* (+ *MIN_X* (/ (+ *MIN_X* *MAX_X*) 2) ) )
(define *START_Y* *MAX_Y*)
(define *START_DEPTH* (+ *MIN_DEPTH* (/ (+ *MIN_DEPTH* *MAX_DEPTH*) 2) ))

(define *POINTS_PER_SEC* 1000)
(define *MAX_INIT_VEL* 7.0)
(define *MAX_LIFE* 5000)
(define *MAX_SCALE* 4.0)

(define *WIND_CHANGE* 2000.0)
(define *MAX_WIND* 3.0)
(define *SPAWN_INTERVAL* 0.01 )
(define *RUNNING_TIME* (* (/ *MAX_LIFE* 1000) 5))
(define *MAX_PTS* (* *RUNNING_TIME* *POINTS_PER_SEC*))

(define init-t 0.0)
(define end-t 0.0)
(define frame-dur 0.0)
(define spwn-tmr 0.0)
(define cleanup-tmr 0.0)
(define run-tmr 0.0)
(define frames (make-vector (* *RUNNING_TIME* 1000) 0.0)  )
(define cur-frame 0)

(define windX 0.0) 
(define windY 0.0)
(define windZ 0.0)
(define grav 0.5)

(define sdl-window #f)
(define sdl-renderer #f)
(define gl-context #f)
(define screen-surface #f)

(define vbo #f)
(define cur-vertex 0)
(define ambient (f32vector 0.8 0.05 0.1 1.0))
(define diffuse (f32vector 1.0 1.0 1.0 1.0))
(define light-pos (f32vector (+ *MIN_X* (/ (- *MAX_X* *MIN_X*) 2) ) *MAX_Y* *MIN_DEPTH* 0.0))

(struct pt (x y z vx vy vz R life is)
  #:mutable
  ) 

(define max-pt 0)      
(define min-pt 0)  
(define seed 1234569)

(define (rand)
  (set! seed (bitwise-xor seed (arithmetic-shift seed 13) ) )
  (set! seed (bitwise-xor seed (arithmetic-shift seed -17) ) )
  (set! seed (bitwise-xor seed (arithmetic-shift seed 5) ) )
  seed
  )

(define pts (make-vector *MAX_PTS* [pt 0 0 0 0 0 0 0 0 0])) 


(define vertex-normal-array
  (f32vector
   -1.0 -1.0 1.0 0.0 0.0 1.0
   1.0 -1.0 1.0 0.0 0.0 1.0
   1.0 1.0 1.0 0.0 0.0 1.0
   -1.0 1.0 1.0 0.0 0.0 1.0
   -1.0 -1.0 -1.0 0.0 0.0 -1.0
   -1.0 1.0 -1.0 0.0 0.0 -1.0
   1.0 1.0 -1.0 0.0 0.0 -1.0
   1.0 -1.0 -1.0 0.0 0.0 -1.0
   -1.0 1.0 -1.0 0.0 1.0 0.0
   -1.0 1.0 1.0 0.0 1.0 0.0
   1.0 1.0 1.0 0.0 1.0 0.0
   1.0 1.0 -1.0 0.0 1.0 0.0
   -1.0 -1.0 -1.0 0.0 -1.0 0.0
   1.0 -1.0 -1.0 0.0 -1.0 0.0
   1.0 -1.0 1.0 0.0 -1.0 0.0
   -1.0 -1.0 1.0 0.0 -1.0 0.0
   1.0 -1.0 -1.0 1.0 0.0 0.0
   1.0 1.0 -1.0 1.0 0.0 0.0
   1.0 1.0 1.0 1.0 0.0 0.0
   1.0 -1.0 1.0 1.0 0.0 0.0
   -1.0 -1.0 -1.0 -1.0 0.0 0.0
   -1.0 -1.0 1.0 -1.0 0.0 0.0
   -1.0 1.0 1.0 -1.0 0.0 0.0
   -1.0 1.0 -1.0 -1.0 0.0 0.0)
  )

(define (new-pt)
  (vector-set! pts max-pt ( pt
                            (- (+ 0 (remainder (rand) *START_RANGE*)) (/ *START_RANGE* 2) )
                            *START_Y*
                            (- (+ *START_DEPTH* (remainder (rand) *START_RANGE*)) (/ *START_RANGE* 2) )
                            (remainder (rand) *MAX_INIT_VEL*)
                            (remainder (rand) *MAX_INIT_VEL*)
                            (remainder (rand) *MAX_INIT_VEL*)
                            (/ (remainder (rand) (* *MAX_SCALE* 100) ) 200)
                            (/ (remainder (rand) *MAX_LIFE*) 1000)
                            1
                            )
               )
  (set! max-pt (+ max-pt 1) )
  )

(define (spwn-pts secs)
  (let ([num (* secs *POINTS_PER_SEC*)])
    (for ([i (in-range 0 num )]) (new-pt) )
    )  
  )

(define (move-pts secs)
  (for ([i (in-range min-pt max-pt)]
        #:when (equal? (pt-is (vector-ref pts i)) 1) )
    (let ([apt (vector-ref pts i)]) (begin
                                      ( set-pt-x! apt (+ (pt-x apt) (* (pt-vx apt) secs) ) )
                                      ( set-pt-y! apt (+ (pt-y apt) (* (pt-vy apt) secs) ) )  
                                      ( set-pt-z! apt (+ (pt-z apt) (* (pt-vz apt) secs) ) )
                                      ( set-pt-vx! apt (+ (pt-vx apt) (* (/ 1 (pt-R apt)) windX)))
                                      ( set-pt-vy! apt (+ (pt-vy apt) (* (/ 1 (pt-R apt)) windY)))
                                      ( set-pt-vz! apt (+ (pt-vz apt) (* (/ 1 (pt-R apt)) windZ)))
                                      ( set-pt-vy! apt (- (pt-vy apt) grav) )
                                      ( set-pt-life! apt (- (pt-life apt) secs) )
                                      ( if (> 0.0 (pt-life apt) ) (set-pt-is! apt 0) #f )
                                      )
      )
    )
  )
(define (check-colls)
  (for ([i (in-range min-pt max-pt)]
        #:when (equal? (pt-is (vector-ref pts i)) 1) ) (begin        
            (if (< (pt-x (vector-ref pts i)) *MIN_X*) (begin 
                                                        (set-pt-x! (vector-ref pts i) (+ *MIN_X* (pt-R (vector-ref pts i))) )
                                                        (set-pt-vx! (vector-ref pts i) (* (pt-vx (vector-ref pts i)) -1.1)) ) #f)
            (if (> (pt-x (vector-ref pts i)) *MAX_X*) (begin 
                                                        (set-pt-x! (vector-ref pts i) (- *MAX_X* (pt-R (vector-ref pts i))) )
                                                        (set-pt-vx! (vector-ref pts i) (* (pt-vx (vector-ref pts i)) -1.1)) ) #f)
            (if (< (pt-y (vector-ref pts i)) *MIN_Y*) (begin 
                                                        (set-pt-y! (vector-ref pts i) (+ *MIN_Y* (pt-R (vector-ref pts i))) )
                                                        (set-pt-vy! (vector-ref pts i) (* (pt-vy (vector-ref pts i)) -1.1)) ) #f)
            (if (> (pt-y (vector-ref pts i)) *MAX_Y*) (begin 
                                                        (set-pt-y! (vector-ref pts i) (- *MAX_Y* (pt-R (vector-ref pts i))) )
                                                        (set-pt-vy! (vector-ref pts i) (* (pt-vy (vector-ref pts i)) -1.1)) ) #f)
            (if (< (pt-z (vector-ref pts i)) *MIN_DEPTH*) (begin 
                                                            (set-pt-z! (vector-ref pts i) (+ *MIN_DEPTH* (pt-R (vector-ref pts i))) )
                                                            (set-pt-vz! (vector-ref pts i) (* (pt-vz (vector-ref pts i)) -1.1)) ) #f)
            (if (> (pt-z (vector-ref pts i)) *MAX_DEPTH*) (begin 
                                                            (set-pt-z! (vector-ref pts i) (- *MAX_DEPTH* (pt-R (vector-ref pts i))) )
                                                            (set-pt-vz! (vector-ref pts i) (* (pt-vz (vector-ref pts i)) -1.1)) ) #f)
            )
    )
  )

(define (do-wind)
  (set! windX (* (- (/ (remainder (rand) *WIND_CHANGE*) *WIND_CHANGE*) (/ *WIND_CHANGE* 2000) ) frame-dur))
  (set! windY (* (- (/ (remainder (rand) *WIND_CHANGE*) *WIND_CHANGE*) (/ *WIND_CHANGE* 2000) ) frame-dur))
  (set! windZ (* (- (/ (remainder (rand) *WIND_CHANGE*) *WIND_CHANGE*) (/ *WIND_CHANGE* 2000) ) frame-dur))
  (if (> (abs windX) *MAX_WIND*) (set! windX (* windX -0.5) ) #f)
  (if (> (abs windY) *MAX_WIND*) (set! windY (* windY -0.5) ) #f)
  (if (> (abs windZ) *MAX_WIND*) (set! windZ (* windZ -0.5) ) #f)
  )

(define (render-pts)
  (for ([i (in-range min-pt max-pt)]
        #:when (equal? (pt-is (vector-ref pts i)) 1) )
    (let ([apt (vector-ref pts i)]) (begin 
                                      (glPopMatrix)
                                      (glPushMatrix) 
                                      (glTranslatef (pt-x apt) (pt-y apt) (- 0 (pt-z apt)) ) 
                                      ;        (glScalef (* (pt-R apt) 2) (* (pt-R apt) 2) (* (pt-R apt) 2))
                                      (glDrawArrays GL_QUADS 0 24)        
                                      ) 
      )
    )
  (SDL_RenderPresent sdl-renderer)
  )

(define (cleanup-pt-pool)
  (for ([i (in-range min-pt max-pt)]
        #:final (equal? (pt-is (vector-ref pts i)) 1) )
    (if (equal? (pt-is (vector-ref pts i)) 1) (set! min-pt i) #f)
    )
  )

(define (load-cube-to-gpu)
  (set! vbo (u32vector-ref (glGenBuffers 1) 0))
  (glBindBuffer GL_ARRAY_BUFFER vbo)
  (glBufferData GL_ARRAY_BUFFER
                (gl-vector-sizeof vertex-normal-array)
                vertex-normal-array
                GL_STATIC_DRAW)
  
  (glEnableClientState GL_VERTEX_ARRAY)
  (glEnableClientState GL_NORMAL_ARRAY)
  (glVertexPointer 3 GL_FLOAT 24 0)
  (glNormalPointer GL_FLOAT 12 0)
  (glMatrixMode GL_MODELVIEW)
  )

(define (init) 
  (SDL_Init SDL_INIT_VIDEO)
  (set! sdl-window (SDL_CreateWindow *TITLE* SDL_WINDOWPOS_UNDEFINED SDL_WINDOWPOS_UNDEFINED *SCREEN_WIDTH* *SCREEN_HEIGHT* #x00000002))
  (set! sdl-renderer (SDL_CreateRenderer sdl-window -1 0))
  (if sdl-window
      (set! screen-surface (SDL_GetWindowSurface sdl-window))
      (printf "Window could not be created! SDL_Error: ~a\n" (SDL_GetError)))
  #t)

(define (init-gl)
  (set! gl-context (SDL_GL_CreateContext sdl-window))
  (SDL_GL_MakeCurrent sdl-window gl-context)  
  (glEnable GL_DEPTH_TEST)
  (glEnable GL_LIGHTING)
  (glClearColor 0.1 0.1 0.6 1.0)
  (glClearDepth 1)
  (glDepthFunc GL_LEQUAL)
  
  (glLightfv GL_LIGHT0 GL_AMBIENT ambient)
  (glLightfv GL_LIGHT0 GL_DIFFUSE diffuse)
  (glLightfv GL_LIGHT0 GL_POSITION light-pos)
  (glEnable GL_LIGHT0)
    
  (glViewport 0 0 *SCREEN_WIDTH* *SCREEN_HEIGHT*)
  (glMatrixMode GL_PROJECTION)
  (glLoadIdentity)
  (glFrustum -1 1 -1 1 1.0 1000.0)
  (glRotatef 20.0 1.0 0.0 0.0)
  (glMatrixMode GL_MODELVIEW)
  (glLoadIdentity)
  (glPushMatrix)
  )

(define (close) 
  (glDisableClientState GL_VERTEX_ARRAY)
  (glDisableClientState GL_NORMAL_ARRAY)
  (SDL_GL_DeleteContext gl-context)
  (SDL_DestroyWindow sdl-window)
  (SDL_Quit))

(define (main-loop)
  (set! init-t (/ (current-inexact-milliseconds) 1000) )
  (move-pts frame-dur)
  (do-wind)
  (if (>= spwn-tmr *SPAWN_INTERVAL*) (begin (spwn-pts *SPAWN_INTERVAL*) (set! spwn-tmr (- spwn-tmr *SPAWN_INTERVAL*)) ) #f)
  (if (>= cleanup-tmr (/ *MAX_LIFE* 1000) ) (begin (cleanup-pt-pool) (set! cleanup-tmr 0) ) #f)
  (check-colls)
  (glClear GL_COLOR_BUFFER_BIT)
  (glClear GL_DEPTH_BUFFER_BIT)
  (render-pts)
  (SDL_GL_SwapWindow sdl-window)
  (set! end-t (/ (current-inexact-milliseconds) 1000) )
  (set! frame-dur (- end-t init-t) )
  (set! spwn-tmr (+ spwn-tmr frame-dur) )
  (set! cleanup-tmr (+ cleanup-tmr frame-dur) )
  (set! run-tmr (+ run-tmr frame-dur) )
  (if (>= run-tmr (/ *MAX_LIFE* 1000) ) (begin ( vector-set! frames cur-frame frame-dur) ( set! cur-frame (+ cur-frame 1) ) ) #f )
  (if (< run-tmr *RUNNING_TIME*) (main-loop)
      (let ([sum 0]) (begin 
                       (for ([i (in-range 0 cur-frame)]) (set! sum (+ sum (vector-ref frames i) ) ) )
                       (display "Average framerate was: ") (display (/ 1 (/ sum cur-frame) ) ) (display " frames per second.\n") )
        )
      )
  )

(init)
(init-gl)
(load-cube-to-gpu)
(main-loop)
(close)