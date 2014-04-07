###
  Copyright (c) 2014 clowwindy
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
###

merge = (left, right, comparison) ->
  result = new Array()
  while (left.length > 0) and (right.length > 0)
    if comparison(left[0], right[0]) <= 0
      result.push left.shift()
    else
      result.push right.shift()
  result.push left.shift()  while left.length > 0
  result.push right.shift()  while right.length > 0
  result
merge_sort = (array, comparison) ->
  return array  if array.length < 2
  middle = Math.ceil(array.length / 2)
  merge merge_sort(array.slice(0, middle), comparison), merge_sort(array.slice(middle), comparison), comparison
exports.merge_sort = merge_sort
