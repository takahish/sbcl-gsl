;;;; gsl/rng.lisp
;;;;
;;;; The library provides a large collection of random number
;;;; generations which can be accessed through a uniform
;;;; interface. Environment variables allow you to select different
;;;; generators and seeds at runtime, so that you can easily switch
;;;; between generators without needing to recompile your program.

;;;; Copyright (C) 2016, 2017 Takahiro Ishikawa
;;;;
;;;; This program is free software: you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation, either version 3 of the License, or
;;;; (at your option) any later version.
;;;;
;;;; This program is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;;;; GNU General Public License for more details.
;;;;
;;;; You should have received a copy of the GNU General Public License
;;;; along with this program. If not, see http://www.gnu.org/licenses/.

(cl:in-package "GSL")


;;; function

(defun gen-rng (n fn &rest args)
  (if (or (null n) (< n 1))
      (apply fn args)
      (let ((acc nil))
        (dotimes (i n (nreverse acc))
          (push (apply fn args) acc)))))

(defun rng-get (rng &optional (n nil))
  "This function returns a random integer from the generator rng. The
minimum and maximum values depend on the algorithm used, but all
integers in the range [min,max] are equally likely. The values of min
and max can be determined using the auxiliary functions (rng-max rng)
and (rng-min rng)."
  (gen-rng n #'gsl_rng_get (pointer rng)))

(defun rng-uniform (rng &optional (n nil))
  "This function retruns a double precision floating point number
uniformly distributed in the range [0,1). The range includes 0.0 but
excludes 1.0. The value is typically obtained by dividing the result
of (rng-get rng) by (+ (rng-max rng) 1.0d0) in double precision. Some
generators compute this ratio internally so that they can provide
floating point numbers with more than 32 bits of randomness (the
maximum number of bits that can be portably represented in a single
unsigned-log)"
  (gen-rng n #'gsl_rng_uniform (pointer rng)))

(defun rng-uniform-pos (rng &optional (n nil))
  "This function returns a positive double precision floating point
number uniformly distributed in the range (0,1), excluding both 0.0
and 1.0. The number is obtained by sampling the generator with the
algorithm of gsl-rng-uniform until a non-zero value is obtained."
  (gen-rng n #'gsl_rng_uniform_pos (pointer rng)))

(defun rng-uniform-int (rng k &optional (n nil))
  "This functions a random integer from 0 to n-1 inclusive by scaling
down and/or discarding samples from the generator rng. All integers in
range [0,n-1] are produced with equal probability. For generators with
a non-zero minimum value an offset is applied so that zero is returned
with the correct probability."
  (gen-rng n #'gsl_rng_uniform_int (pointer rng)
           (coerce k `(unsigned-byte
                       ,(* (cffi:foreign-type-size :unsigned-long) 8)))))

(defun rng-name (rng)
  "This function return a pointer to the name of the generator."
  (gsl_rng_name (pointer rng)))

(defun rng-max (rng)
  "rng-max returns the largest value that rng-get can return."
  (gsl_rng_max (pointer rng)))

(defun rng-min (rng)
  "rng-min returns the smallest value that rng-get can return. Usually
this value is zero. There are smallest generators with algorithms that
cannot return zero, and for these generators the minimum value is 1."
  (gsl_rng_min (pointer rng)))

(defun rng-state (rng)
  "This function return a pointer to the state of generator rng."
  (gsl_rng_state (pointer rng)))

(defun rng-size (rng)
  "This function return a pointer to the size of generator rng."
  (gsl_rng_size (pointer rng)))

(defun rng-env-setup ()
  "This function reads the environment variables GSL_RNG_TYPE and
GSL_RNG_SEED and uses their values to set the corresponding library
variables *rng-type* and *rng-seed*. These global variables are
defined as follows,

  (*rng-default* (:pointer (:struct gsl_rng_type)))
  (*rng-default-seed* :unsigned-long)

The environment variable GSL_RNG_TYPE should be the name of a
generator, such as taus or mt19937. The environment variable
GSL_RNG_SEED should contain the desired seed value. It is converted to
an unsigned long int using the C library function strtoul.
If you don't specify a generator for GSL_RNG_TYPE then gsl_rng_mt19937
is used as the default. The initial value of gsl_rng_default_seed is
zero."
  (gsl_rng_env_setup)
  (setf *rng-default* gsl_rng_default)
  (setf *rng-default-seed* gsl_rng_default_seed))

(defun rng-memcpy (dest src)
  "This function copies the random number generator src into the
pre-existing generator dest, making dest into an exact copy of
src. The two generators must be of the same type."
  (gsl_rng_memcpy (pointer dest) (pointer src))
  dest)

(defun rng-clone (rng)
  "This function returns a pointer to a newly created generator which
is an exact copy of the generator rng."
  (make-instance 'rng :pointer (gsl_rng_clone (pointer rng))))
