(function () { "use strict";
var $_;
var Visibility = function() {
	this.segments = new de.polygonal.ds.DLL();
	this.endpoints = new de.polygonal.ds.DLL();
	this.open = new de.polygonal.ds.DLL();
	this.center = { x : 0.0, y : 0.0};
	this.output = new Array();
	this.demo_intersectionsDetected = [];
};
$hxExpose(Visibility, "Visibility");
Visibility.__name__ = ["Visibility"];
Visibility._endpoint_compare = function(a,b) {
	if(a.angle > b.angle) return 1;
	if(a.angle < b.angle) return -1;
	if(!a.begin && b.begin) return 1;
	if(a.begin && !b.begin) return -1;
	return 0;
}
Visibility.leftOf = function(s,p) {
	var cross = (s.p2.x - s.p1.x) * (p.y - s.p1.y) - (s.p2.y - s.p1.y) * (p.x - s.p1.x);
	return cross < 0;
}
Visibility.interpolate = function(p,q,f) {
	return { x : p.x * (1 - f) + q.x * f, y : p.y * (1 - f) + q.y * f};
}
Visibility.prototype = {
	loadEdgeOfMap: function(size,margin) {
		this.addSegment(margin,margin,margin,size - margin);
		this.addSegment(margin,size - margin,size - margin,size - margin);
		this.addSegment(size - margin,size - margin,size - margin,margin);
		this.addSegment(size - margin,margin,margin,margin);
	}
	,loadMap: function(size,margin,blocks,walls) {
		this.segments.clear(null);
		this.endpoints.clear(null);
		this.loadEdgeOfMap(size,margin);
		var _g = 0;
		while(_g < blocks.length) {
			var block = blocks[_g];
			++_g;
			var x = block.x;
			var y = block.y;
			var r = block.r;
			this.addSegment(x - r,y - r,x - r,y + r);
			this.addSegment(x - r,y + r,x + r,y + r);
			this.addSegment(x + r,y + r,x + r,y - r);
			this.addSegment(x + r,y - r,x - r,y - r);
		}
		var _g = 0;
		while(_g < walls.length) {
			var wall = walls[_g];
			++_g;
			this.addSegment(wall.p1.x,wall.p1.y,wall.p2.x,wall.p2.y);
		}
	}
	,addSegment: function(x1,y1,x2,y2) {
		var segment = null;
		var p1 = { begin : false, x : 0.0, y : 0.0, angle : 0.0, segment : segment, visualize : true};
		var p2 = { begin : false, x : 0.0, y : 0.0, angle : 0.0, segment : segment, visualize : false};
		segment = { p1 : p1, p2 : p2, d : 0.0};
		p1.x = x1;
		p1.y = y1;
		p2.x = x2;
		p2.y = y2;
		p1.segment = segment;
		p2.segment = segment;
		segment.p1 = p1;
		segment.p2 = p2;
		this.segments.append(segment);
		this.endpoints.append(p1);
		this.endpoints.append(p2);
	}
	,setLightLocation: function(x,y) {
		this.center.x = x;
		this.center.y = y;
		var $it0 = this.segments.iterator();
		while( $it0.hasNext() ) {
			var segment = $it0.next();
			var dx = 0.5 * (segment.p1.x + segment.p2.x) - x;
			var dy = 0.5 * (segment.p1.y + segment.p2.y) - y;
			segment.d = dx * dx + dy * dy;
			segment.p1.angle = Math.atan2(segment.p1.y - y,segment.p1.x - x);
			segment.p2.angle = Math.atan2(segment.p2.y - y,segment.p2.x - x);
			var dAngle = segment.p2.angle - segment.p1.angle;
			if(dAngle <= -Math.PI) dAngle += 2 * Math.PI;
			if(dAngle > Math.PI) dAngle -= 2 * Math.PI;
			segment.p1.begin = dAngle > 0.0;
			segment.p2.begin = !segment.p1.begin;
		}
	}
	,_segment_in_front_of: function(a,b,relativeTo) {
		var A1 = Visibility.leftOf(a,Visibility.interpolate(b.p1,b.p2,0.01));
		var A2 = Visibility.leftOf(a,Visibility.interpolate(b.p2,b.p1,0.01));
		var A3 = Visibility.leftOf(a,relativeTo);
		var B1 = Visibility.leftOf(b,Visibility.interpolate(a.p1,a.p2,0.01));
		var B2 = Visibility.leftOf(b,Visibility.interpolate(a.p2,a.p1,0.01));
		var B3 = Visibility.leftOf(b,relativeTo);
		if(B1 == B2 && B2 != B3) return true;
		if(A1 == A2 && A2 == A3) return true;
		if(A1 == A2 && A2 != A3) return false;
		if(B1 == B2 && B2 == B3) return false;
		this.demo_intersectionsDetected.push([a.p1,a.p2,b.p1,b.p2]);
		return false;
	}
	,sweep: function(maxAngle) {
		if(maxAngle == null) maxAngle = 999.0;
		this.output = [];
		this.demo_intersectionsDetected = [];
		this.endpoints.sort(Visibility._endpoint_compare,true);
		this.open.clear(null);
		var beginAngle = 0.0;
		var _g = 0;
		while(_g < 2) {
			var pass = _g++;
			var $it0 = this.endpoints.iterator();
			while( $it0.hasNext() ) {
				var p = $it0.next();
				if(pass == 1 && p.angle > maxAngle) break;
				var current_old = this.open._size == 0?null:this.open.head.val;
				if(p.begin) {
					var node = this.open.head;
					while(node != null && this._segment_in_front_of(p.segment,node.val,this.center)) node = node.next;
					if(node == null) this.open.append(p.segment); else this.open.insertBefore(node,p.segment);
				} else this.open.remove(p.segment);
				var current_new = this.open._size == 0?null:this.open.head.val;
				if(current_old != current_new) {
					if(pass == 1) this.addTriangle(beginAngle,p.angle,current_old);
					beginAngle = p.angle;
				}
			}
		}
	}
	,lineIntersection: function(p1,p2,p3,p4) {
		var s = ((p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)) / ((p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y));
		return { x : p1.x + s * (p2.x - p1.x), y : p1.y + s * (p2.y - p1.y)};
	}
	,addTriangle: function(angle1,angle2,segment) {
		var p1 = this.center;
		var p2 = { x : this.center.x + Math.cos(angle1), y : this.center.y + Math.sin(angle1)};
		var p3 = { x : 0.0, y : 0.0};
		var p4 = { x : 0.0, y : 0.0};
		if(segment != null) {
			p3.x = segment.p1.x;
			p3.y = segment.p1.y;
			p4.x = segment.p2.x;
			p4.y = segment.p2.y;
		} else {
			p3.x = this.center.x + Math.cos(angle1) * 5;
			p3.y = this.center.y + Math.sin(angle1) * 5;
			p4.x = this.center.x + Math.cos(angle2) * 5;
			p4.y = this.center.y + Math.cos(angle2) * 5;
		}
		var pBegin = this.lineIntersection(p3,p4,p1,p2);
		p2.x = this.center.x + Math.cos(angle2);
		p2.y = this.center.y + Math.sin(angle2);
		var pEnd = this.lineIntersection(p3,p4,p1,p2);
		this.output.push(pBegin);
		this.output.push(pEnd);
	}
	,__class__: Visibility
}
var de = {}
de.polygonal = {}
de.polygonal.ds = {}
de.polygonal.ds.ArrayUtil = function() { }
de.polygonal.ds.ArrayUtil.__name__ = ["de","polygonal","ds","ArrayUtil"];
de.polygonal.ds.ArrayUtil.alloc = function(x) {
	var a;
	a = new Array(x);
	return a;
}
de.polygonal.ds.ArrayUtil.prototype = {
	__class__: de.polygonal.ds.ArrayUtil
}
de.polygonal.ds.Cloneable = function() { }
de.polygonal.ds.Cloneable.__name__ = ["de","polygonal","ds","Cloneable"];
de.polygonal.ds.Cloneable.prototype = {
	__class__: de.polygonal.ds.Cloneable
}
de.polygonal.ds.Hashable = function() { }
de.polygonal.ds.Hashable.__name__ = ["de","polygonal","ds","Hashable"];
de.polygonal.ds.Hashable.prototype = {
	__class__: de.polygonal.ds.Hashable
}
de.polygonal.ds.Collection = function() { }
de.polygonal.ds.Collection.__name__ = ["de","polygonal","ds","Collection"];
de.polygonal.ds.Collection.__interfaces__ = [de.polygonal.ds.Hashable];
de.polygonal.ds.Collection.prototype = {
	__class__: de.polygonal.ds.Collection
}
de.polygonal.ds.DA = function(reservedSize,maxSize) {
	if(maxSize == null) maxSize = -1;
	if(reservedSize == null) reservedSize = 0;
	this._size = 0;
	this._iterator = null;
	this.maxSize = -1;
	if(reservedSize > 0) this._a = de.polygonal.ds.ArrayUtil.alloc(reservedSize); else this._a = new Array();
	this.key = de.polygonal.ds.HashKey._counter++;
	this.reuseIterator = false;
};
de.polygonal.ds.DA.__name__ = ["de","polygonal","ds","DA"];
de.polygonal.ds.DA.__interfaces__ = [de.polygonal.ds.Collection];
de.polygonal.ds.DA.prototype = {
	set: function(i,x) {
		this._a[i] = x;
		if(i >= this._size) this._size++;
	}
	,pushBack: function(x) {
		this.set(this._size,x);
	}
	,removeAt: function(i) {
		var x = this._a[i];
		var k = this._size - 1;
		var p = i;
		while(p < k) this._a[p++] = this._a[p];
		this._size--;
		return x;
	}
	,free: function() {
		var NULL = null;
		var _g1 = 0, _g = this._a.length;
		while(_g1 < _g) {
			var i = _g1++;
			this._a[i] = NULL;
		}
		this._a = null;
		this._iterator = null;
	}
	,contains: function(x) {
		var found = false;
		var _g1 = 0, _g = this._size;
		while(_g1 < _g) {
			var i = _g1++;
			if(this._a[i] == x) {
				found = true;
				break;
			}
		}
		return found;
	}
	,remove: function(x) {
		if(this._size == 0) return false;
		var i = 0;
		var s = this._size;
		while(i < s) {
			if(this._a[i] == x) {
				s--;
				var p = i;
				while(p < s) {
					this._a[p] = this._a[p + 1];
					++p;
				}
				continue;
			}
			i++;
		}
		var found = this._size - s != 0;
		this._size = s;
		return found;
	}
	,clear: function(purge) {
		if(purge == null) purge = false;
		if(purge) {
			var NULL = null;
			var _g1 = 0, _g = this._a.length;
			while(_g1 < _g) {
				var i = _g1++;
				this._a[i] = NULL;
			}
		}
		this._size = 0;
	}
	,iterator: function() {
		if(this.reuseIterator) {
			if(this._iterator == null) this._iterator = new de.polygonal.ds.DAIterator(this); else this._iterator.reset();
			return this._iterator;
		} else return new de.polygonal.ds.DAIterator(this);
	}
	,size: function() {
		return this._size;
	}
	,isEmpty: function() {
		return this._size == 0;
	}
	,toArray: function() {
		var a = de.polygonal.ds.ArrayUtil.alloc(this._size);
		var _g1 = 0, _g = this._size;
		while(_g1 < _g) {
			var i = _g1++;
			a[i] = this._a[i];
		}
		return a;
	}
	,toDA: function() {
		var a = new de.polygonal.ds.DA(this._size);
		var _g1 = 0, _g = this._size;
		while(_g1 < _g) {
			var i = _g1++;
			a.set(a._size,this._a[i]);
		}
		return a;
	}
	,clone: function(assign,copier) {
		if(assign == null) assign = true;
		var copy = new de.polygonal.ds.DA(this._size,this.maxSize);
		copy._size = this._size;
		if(assign) {
			var _g1 = 0, _g = this._size;
			while(_g1 < _g) {
				var i = _g1++;
				copy._a[i] = this._a[i];
			}
		} else if(copier == null) {
			var c = null;
			var _g1 = 0, _g = this._size;
			while(_g1 < _g) {
				var i = _g1++;
				c = this._a[i];
				copy._a[i] = c.clone();
			}
		} else {
			var _g1 = 0, _g = this._size;
			while(_g1 < _g) {
				var i = _g1++;
				copy._a[i] = copier(this._a[i]);
			}
		}
		return copy;
	}
	,__get: function(i) {
		return this._a[i];
	}
	,__set: function(i,x) {
		this._a[i] = x;
	}
	,__cpy: function(i,j) {
		this._a[i] = this._a[j];
	}
	,__class__: de.polygonal.ds.DA
}
de.polygonal.ds.Itr = function() { }
de.polygonal.ds.Itr.__name__ = ["de","polygonal","ds","Itr"];
de.polygonal.ds.Itr.prototype = {
	__class__: de.polygonal.ds.Itr
}
de.polygonal.ds.DAIterator = function(f) {
	this._f = f;
	{
		this._a = this._f._a;
		this._s = this._f._size;
		this._i = 0;
		this;
	}
};
de.polygonal.ds.DAIterator.__name__ = ["de","polygonal","ds","DAIterator"];
de.polygonal.ds.DAIterator.__interfaces__ = [de.polygonal.ds.Itr];
de.polygonal.ds.DAIterator.prototype = {
	reset: function() {
		this._a = this._f._a;
		this._s = this._f._size;
		this._i = 0;
		return this;
	}
	,hasNext: function() {
		return this._i < this._s;
	}
	,next: function() {
		return this._a[this._i++];
	}
	,remove: function() {
		this._f.removeAt(--this._i);
		this._s--;
	}
	,__a: function(f) {
		return f._a;
	}
	,__size: function(f) {
		return f._size;
	}
	,__class__: de.polygonal.ds.DAIterator
}
de.polygonal.ds.DLL = function(reservedSize,maxSize) {
	if(maxSize == null) maxSize = -1;
	if(reservedSize == null) reservedSize = 0;
	this.maxSize = -1;
	this._reservedSize = reservedSize;
	this._size = 0;
	this._poolSize = 0;
	this._circular = false;
	this._iterator = null;
	if(reservedSize > 0) {
		var NULL = null;
		this._headPool = this._tailPool = new de.polygonal.ds.DLLNode(NULL,this);
	}
	this.head = this.tail = null;
	this.key = de.polygonal.ds.HashKey._counter++;
	this.reuseIterator = false;
};
de.polygonal.ds.DLL.__name__ = ["de","polygonal","ds","DLL"];
de.polygonal.ds.DLL.__interfaces__ = [de.polygonal.ds.Collection];
de.polygonal.ds.DLL.prototype = {
	append: function(x) {
		var node = this._getNode(x);
		if(this.tail != null) {
			this.tail.next = node;
			node.prev = this.tail;
		} else this.head = node;
		this.tail = node;
		if(this._circular) {
			this.tail.next = this.head;
			this.head.prev = this.tail;
		}
		this._size++;
		return node;
	}
	,insertBefore: function(node,x) {
		var t = this._getNode(x);
		node._insertBefore(t);
		if(node == this.head) {
			this.head = t;
			if(this._circular) this.head.prev = this.tail;
		}
		this._size++;
		return t;
	}
	,unlink: function(node) {
		var hook = node.next;
		if(node == this.head) {
			this.head = this.head.next;
			if(this._circular) {
				if(this.head == this.tail) this.head = null; else this.tail.next = this.head;
			}
			if(this.head == null) this.tail = null;
		} else if(node == this.tail) {
			this.tail = this.tail.prev;
			if(this._circular) this.head.prev = this.tail;
			if(this.tail == null) this.head = null;
		}
		node._unlink();
		this._putNode(node);
		this._size--;
		return hook;
	}
	,sort: function(compare,useInsertionSort) {
		if(useInsertionSort == null) useInsertionSort = false;
		if(this._size > 1) {
			if(this._circular) {
				this.tail.next = null;
				this.head.prev = null;
			}
			if(compare == null) this.head = useInsertionSort?this._insertionSortComparable(this.head):this._mergeSortComparable(this.head); else this.head = useInsertionSort?this._insertionSort(this.head,compare):this._mergeSort(this.head,compare);
			if(this._circular) {
				this.tail.next = this.head;
				this.head.prev = this.tail;
			}
		}
	}
	,free: function() {
		var NULL = null;
		var node = this.head;
		var _g1 = 0, _g = this._size;
		while(_g1 < _g) {
			var i = _g1++;
			var next = node.next;
			node.next = node.prev = null;
			node.val = NULL;
			node = next;
		}
		this.head = this.tail = null;
		var node1 = this._headPool;
		while(node1 != null) {
			var next = node1.next;
			node1.next = null;
			node1.val = NULL;
			node1 = next;
		}
		this._headPool = this._tailPool = null;
		this._iterator = null;
	}
	,contains: function(x) {
		var node = this.head;
		var _g1 = 0, _g = this._size;
		while(_g1 < _g) {
			var i = _g1++;
			if(node.val == x) return true;
			node = node.next;
		}
		return false;
	}
	,remove: function(x) {
		var s = this._size;
		if(s == 0) return false;
		var node = this.head;
		while(node != null) if(node.val == x) node = this.unlink(node); else node = node.next;
		return this._size < s;
	}
	,clear: function(purge) {
		if(purge == null) purge = false;
		if(purge || this._reservedSize > 0) {
			var node = this.head;
			var _g1 = 0, _g = this._size;
			while(_g1 < _g) {
				var i = _g1++;
				var next = node.next;
				node.prev = null;
				node.next = null;
				this._putNode(node);
				node = next;
			}
		}
		this.head = this.tail = null;
		this._size = 0;
	}
	,iterator: function() {
		if(this.reuseIterator) {
			if(this._iterator == null) {
				if(this._circular) return new de.polygonal.ds.CircularDLLIterator(this); else return new de.polygonal.ds.DLLIterator(this);
			} else this._iterator.reset();
			return this._iterator;
		} else if(this._circular) return new de.polygonal.ds.CircularDLLIterator(this); else return new de.polygonal.ds.DLLIterator(this);
	}
	,size: function() {
		return this._size;
	}
	,isEmpty: function() {
		return this._size == 0;
	}
	,toArray: function() {
		var a = de.polygonal.ds.ArrayUtil.alloc(this._size);
		var node = this.head;
		var _g1 = 0, _g = this._size;
		while(_g1 < _g) {
			var i = _g1++;
			a[i] = node.val;
			node = node.next;
		}
		return a;
	}
	,toDA: function() {
		var a = new de.polygonal.ds.DA(this._size);
		var node = this.head;
		var _g1 = 0, _g = this._size;
		while(_g1 < _g) {
			var i = _g1++;
			a.set(a._size,node.val);
			node = node.next;
		}
		return a;
	}
	,clone: function(assign,copier) {
		if(assign == null) assign = true;
		if(this._size == 0) {
			var copy = new de.polygonal.ds.DLL(this._reservedSize,this.maxSize);
			if(this._circular) copy._circular = true;
			return copy;
		}
		var copy = new de.polygonal.ds.DLL();
		copy._size = this._size;
		if(assign) {
			var srcNode = this.head;
			var dstNode = copy.head = new de.polygonal.ds.DLLNode(this.head.val,copy);
			if(this._size == 1) {
				copy.tail = copy.head;
				if(this._circular) copy.tail.next = copy.head;
				return copy;
			}
			var dstNode0;
			srcNode = srcNode.next;
			var _g1 = 1, _g = this._size - 1;
			while(_g1 < _g) {
				var i = _g1++;
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				dstNode = dstNode.next = new de.polygonal.ds.DLLNode(srcNode.val,copy);
				dstNode.prev = dstNode0;
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			dstNode0 = dstNode;
			copy.tail = dstNode.next = new de.polygonal.ds.DLLNode(srcNode.val,copy);
			copy.tail.prev = dstNode0;
		} else if(copier == null) {
			var srcNode = this.head;
			var c = this.head.val;
			var dstNode = copy.head = new de.polygonal.ds.DLLNode(c.clone(),copy);
			if(this._size == 1) {
				copy.tail = copy.head;
				if(this._circular) copy.tail.next = copy.head;
				return copy;
			}
			var dstNode0;
			srcNode = srcNode.next;
			var _g1 = 1, _g = this._size - 1;
			while(_g1 < _g) {
				var i = _g1++;
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				c = srcNode.val;
				dstNode = dstNode.next = new de.polygonal.ds.DLLNode(c.clone(),copy);
				dstNode.prev = dstNode0;
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			c = srcNode.val;
			dstNode0 = dstNode;
			copy.tail = dstNode.next = new de.polygonal.ds.DLLNode(c.clone(),copy);
			copy.tail.prev = dstNode0;
		} else {
			var srcNode = this.head;
			var dstNode = copy.head = new de.polygonal.ds.DLLNode(copier(this.head.val),copy);
			if(this._size == 1) {
				copy.tail = copy.head;
				if(this._circular) copy.tail.next = copy.head;
				return copy;
			}
			var dstNode0;
			srcNode = srcNode.next;
			var _g1 = 1, _g = this._size - 1;
			while(_g1 < _g) {
				var i = _g1++;
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				dstNode = dstNode.next = new de.polygonal.ds.DLLNode(copier(srcNode.val),copy);
				dstNode.prev = dstNode0;
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			dstNode0 = dstNode;
			copy.tail = dstNode.next = new de.polygonal.ds.DLLNode(copier(srcNode.val),copy);
			copy.tail.prev = dstNode0;
		}
		if(this._circular) copy.tail.next = copy.head;
		return copy;
	}
	,_mergeSortComparable: function(node) {
		var h = node;
		var p, q, e, tail = null;
		var insize = 1;
		var nmerges, psize, qsize, i;
		while(true) {
			p = h;
			h = tail = null;
			nmerges = 0;
			while(p != null) {
				nmerges++;
				psize = 0;
				q = p;
				var _g = 0;
				while(_g < insize) {
					var i1 = _g++;
					psize++;
					q = q.next;
					if(q == null) break;
				}
				qsize = insize;
				while(psize > 0 || qsize > 0 && q != null) {
					if(psize == 0) {
						e = q;
						q = q.next;
						qsize--;
					} else if(qsize == 0 || q == null) {
						e = p;
						p = p.next;
						psize--;
					} else if(p.val.compare(q.val) >= 0) {
						e = p;
						p = p.next;
						psize--;
					} else {
						e = q;
						q = q.next;
						qsize--;
					}
					if(tail != null) tail.next = e; else h = e;
					e.prev = tail;
					tail = e;
				}
				p = q;
			}
			tail.next = null;
			if(nmerges <= 1) break;
			insize <<= 1;
		}
		h.prev = null;
		this.tail = tail;
		return h;
	}
	,_mergeSort: function(node,cmp) {
		var h = node;
		var p, q, e, tail = null;
		var insize = 1;
		var nmerges, psize, qsize, i;
		while(true) {
			p = h;
			h = tail = null;
			nmerges = 0;
			while(p != null) {
				nmerges++;
				psize = 0;
				q = p;
				var _g = 0;
				while(_g < insize) {
					var i1 = _g++;
					psize++;
					q = q.next;
					if(q == null) break;
				}
				qsize = insize;
				while(psize > 0 || qsize > 0 && q != null) {
					if(psize == 0) {
						e = q;
						q = q.next;
						qsize--;
					} else if(qsize == 0 || q == null) {
						e = p;
						p = p.next;
						psize--;
					} else if(cmp(q.val,p.val) >= 0) {
						e = p;
						p = p.next;
						psize--;
					} else {
						e = q;
						q = q.next;
						qsize--;
					}
					if(tail != null) tail.next = e; else h = e;
					e.prev = tail;
					tail = e;
				}
				p = q;
			}
			tail.next = null;
			if(nmerges <= 1) break;
			insize <<= 1;
		}
		h.prev = null;
		this.tail = tail;
		return h;
	}
	,_insertionSortComparable: function(node) {
		var h = node;
		var n = h.next;
		while(n != null) {
			var m = n.next;
			var p = n.prev;
			var v = n.val;
			if(p.val.compare(v) < 0) {
				var i = p;
				while(i.prev != null) if(i.prev.val.compare(v) < 0) i = i.prev; else break;
				if(m != null) {
					p.next = m;
					m.prev = p;
				} else {
					p.next = null;
					this.tail = p;
				}
				if(i == h) {
					n.prev = null;
					n.next = i;
					i.prev = n;
					h = n;
				} else {
					n.prev = i.prev;
					i.prev.next = n;
					n.next = i;
					i.prev = n;
				}
			}
			n = m;
		}
		return h;
	}
	,_insertionSort: function(node,cmp) {
		var h = node;
		var n = h.next;
		while(n != null) {
			var m = n.next;
			var p = n.prev;
			var v = n.val;
			if(cmp(v,p.val) < 0) {
				var i = p;
				while(i.prev != null) if(cmp(v,i.prev.val) < 0) i = i.prev; else break;
				if(m != null) {
					p.next = m;
					m.prev = p;
				} else {
					p.next = null;
					this.tail = p;
				}
				if(i == h) {
					n.prev = null;
					n.next = i;
					i.prev = n;
					h = n;
				} else {
					n.prev = i.prev;
					i.prev.next = n;
					n.next = i;
					i.prev = n;
				}
			}
			n = m;
		}
		return h;
	}
	,_valid: function(node) {
		return node != null;
	}
	,_getNode: function(x) {
		if(this._reservedSize == 0 || this._poolSize == 0) return new de.polygonal.ds.DLLNode(x,this); else {
			var n = this._headPool;
			this._headPool = this._headPool.next;
			this._poolSize--;
			n.next = null;
			n.val = x;
			return n;
		}
	}
	,_putNode: function(x) {
		var val = x.val;
		if(this._reservedSize > 0 && this._poolSize < this._reservedSize) {
			this._tailPool = this._tailPool.next = x;
			var NULL = null;
			x.val = NULL;
			this._poolSize++;
		} else x._list = null;
		return val;
	}
	,__insertBefore: function(f,x) {
		f._insertBefore(x);
	}
	,__unlink: function(f) {
		f._unlink();
	}
	,__list: function(f,x) {
		f._list = x;
	}
	,__class__: de.polygonal.ds.DLL
}
de.polygonal.ds.DLLIterator = function(f) {
	this._f = f;
	{
		this._walker = this._f.head;
		this._hook = null;
		this;
	}
};
de.polygonal.ds.DLLIterator.__name__ = ["de","polygonal","ds","DLLIterator"];
de.polygonal.ds.DLLIterator.__interfaces__ = [de.polygonal.ds.Itr];
de.polygonal.ds.DLLIterator.prototype = {
	reset: function() {
		this._walker = this._f.head;
		this._hook = null;
		return this;
	}
	,hasNext: function() {
		return this._walker != null;
	}
	,next: function() {
		var x = this._walker.val;
		this._hook = this._walker;
		this._walker = this._walker.next;
		return x;
	}
	,remove: function() {
		this._f.unlink(this._hook);
	}
	,__class__: de.polygonal.ds.DLLIterator
}
de.polygonal.ds.CircularDLLIterator = function(f) {
	this._f = f;
	{
		this._walker = this._f.head;
		this._s = this._f._size;
		this._i = 0;
		this._hook = null;
		this;
	}
};
de.polygonal.ds.CircularDLLIterator.__name__ = ["de","polygonal","ds","CircularDLLIterator"];
de.polygonal.ds.CircularDLLIterator.__interfaces__ = [de.polygonal.ds.Itr];
de.polygonal.ds.CircularDLLIterator.prototype = {
	reset: function() {
		this._walker = this._f.head;
		this._s = this._f._size;
		this._i = 0;
		this._hook = null;
		return this;
	}
	,hasNext: function() {
		return this._i < this._s;
	}
	,next: function() {
		var x = this._walker.val;
		this._hook = this._walker;
		this._walker = this._walker.next;
		this._i++;
		return x;
	}
	,remove: function() {
		this._f.unlink(this._hook);
		this._i--;
		this._s--;
	}
	,__class__: de.polygonal.ds.CircularDLLIterator
}
de.polygonal.ds.DLLNode = function(x,list) {
	this.val = x;
	this._list = list;
};
de.polygonal.ds.DLLNode.__name__ = ["de","polygonal","ds","DLLNode"];
de.polygonal.ds.DLLNode.prototype = {
	hasNext: function() {
		return this.next != null;
	}
	,hasPrev: function() {
		return this.prev != null;
	}
	,_unlink: function() {
		var t = this.next;
		if(this.prev != null) this.prev.next = this.next;
		if(this.next != null) this.next.prev = this.prev;
		this.next = this.prev = null;
		return t;
	}
	,_insertAfter: function(node) {
		node.next = this.next;
		node.prev = this;
		if(this.next != null) this.next.prev = node;
		this.next = node;
	}
	,_insertBefore: function(node) {
		node.next = this;
		node.prev = this.prev;
		if(this.prev != null) this.prev.next = node;
		this.prev = node;
	}
	,__class__: de.polygonal.ds.DLLNode
}
de.polygonal.ds.HashKey = function() { }
de.polygonal.ds.HashKey.__name__ = ["de","polygonal","ds","HashKey"];
de.polygonal.ds.HashKey.next = function() {
	return de.polygonal.ds.HashKey._counter++;
}
de.polygonal.ds.HashKey.prototype = {
	__class__: de.polygonal.ds.HashKey
}
var js = {}
js.Boot = function() { }
js.Boot.__name__ = ["js","Boot"];
js.Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ != null || o.__ename__ != null)) t = "object";
	switch(t) {
	case "object":
		if(o instanceof Array) {
			if(o.__enum__ != null) {
				if(o.length == 2) return o[0];
				var str = o[0] + "(";
				s += "\t";
				var _g1 = 2, _g = o.length;
				while(_g1 < _g) {
					var i = _g1++;
					if(i != 2) str += "," + js.Boot.__string_rec(o[i],s); else str += js.Boot.__string_rec(o[i],s);
				}
				return str + ")";
			}
			var l = o.length;
			var i;
			var str = "[";
			s += "\t";
			var _g = 0;
			while(_g < l) {
				var i1 = _g++;
				str += (i1 > 0?",":"") + js.Boot.__string_rec(o[i1],s);
			}
			str += "]";
			return str;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e ) {
			return "???";
		}
		if(tostr != null && tostr != Object.toString) {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		for( var k in o ) { ;
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str.length != 2) str += ", \n";
		str += s + k + " : " + js.Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	case "function":
		return "<function>";
	case "string":
		return o;
	default:
		return String(o);
	}
}
js.Boot.__interfLoop = function(cc,cl) {
	if(cc == null) return false;
	if(cc == cl) return true;
	var intf = cc.__interfaces__;
	if(intf != null) {
		var _g1 = 0, _g = intf.length;
		while(_g1 < _g) {
			var i = _g1++;
			var i1 = intf[i];
			if(i1 == cl || js.Boot.__interfLoop(i1,cl)) return true;
		}
	}
	return js.Boot.__interfLoop(cc.__super__,cl);
}
js.Boot.__instanceof = function(o,cl) {
	try {
		if(o instanceof cl) {
			if(cl == Array) return o.__enum__ == null;
			return true;
		}
		if(js.Boot.__interfLoop(o.__class__,cl)) return true;
	} catch( e ) {
		if(cl == null) return false;
	}
	switch(cl) {
	case Int:
		return Math.ceil(o%2147483648.0) === o;
	case Float:
		return typeof(o) == "number";
	case Bool:
		return o === true || o === false;
	case String:
		return typeof(o) == "string";
	case Dynamic:
		return true;
	default:
		if(o == null) return false;
		return o.__enum__ == cl || cl == Class && o.__name__ != null || cl == Enum && o.__ename__ != null;
	}
}
js.Boot.__init = function() {
	Array.prototype.copy = Array.prototype.slice;
	Array.prototype.insert = function(i,x) {
		this.splice(i,0,x);
	};
	Array.prototype.remove = Array.prototype.indexOf?function(obj) {
		var idx = this.indexOf(obj);
		if(idx == -1) return false;
		this.splice(idx,1);
		return true;
	}:function(obj) {
		var i = 0;
		var l = this.length;
		while(i < l) {
			if(this[i] == obj) {
				this.splice(i,1);
				return true;
			}
			i++;
		}
		return false;
	};
	Array.prototype.iterator = function() {
		return { cur : 0, arr : this, hasNext : function() {
			return this.cur < this.arr.length;
		}, next : function() {
			return this.arr[this.cur++];
		}};
	};
	if(String.prototype.cca == null) String.prototype.cca = String.prototype.charCodeAt;
	String.prototype.charCodeAt = function(i) {
		var x = this.cca(i);
		if(x != x) return undefined;
		return x;
	};
	var oldsub = String.prototype.substr;
	String.prototype.substr = function(pos,len) {
		if(pos != null && pos != 0 && len != null && len < 0) return "";
		if(len == null) len = this.length;
		if(pos < 0) {
			pos = this.length + pos;
			if(pos < 0) pos = 0;
		} else if(len < 0) len = this.length + len - pos;
		return oldsub.apply(this,[pos,len]);
	};
	Function.prototype["$bind"] = function(o) {
		var f = function() {
			return f.method.apply(f.scope,arguments);
		};
		f.scope = o;
		f.method = this;
		return f;
	};
}
js.Boot.prototype = {
	__class__: js.Boot
}
js.Boot.__res = {}
js.Boot.__init();
{
	Math.__name__ = ["Math"];
	Math.NaN = Number["NaN"];
	Math.NEGATIVE_INFINITY = Number["NEGATIVE_INFINITY"];
	Math.POSITIVE_INFINITY = Number["POSITIVE_INFINITY"];
	;
	Math.isFinite = function(i) {
		return isFinite(i);
	};
	Math.isNaN = function(i) {
		return isNaN(i);
	};
}
{
	String.prototype.__class__ = String;
	String.__name__ = ["String"];
	Array.prototype.__class__ = Array;
	Array.__name__ = ["Array"];
	var Int = { __name__ : ["Int"]};
	var Dynamic = { __name__ : ["Dynamic"]};
	var Float = Number;
	Float.__name__ = ["Float"];
	var Bool = Boolean;
	Bool.__ename__ = ["Bool"];
	var Class = { __name__ : ["Class"]};
	var Enum = { };
	var Void = { __ename__ : ["Void"]};
}
de.polygonal.ds.HashKey._counter = 0;
;
function $hxExpose(src, path) {
	var o = window;
	var parts = path.split(".");
	for(var ii = 0; ii < parts.length-1; ++ii) {
		var p = parts[ii];
		if(typeof o[p] == "undefined") o[p] = {};
		o = o[p];
	}
	o[parts[parts.length-1]] = src;
}
})()
