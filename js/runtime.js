var PYRET = (function () {

  function makeRuntime() {

    function PBase() {

    }

    PBase.prototype = {
        dict : {}
        app : function() {throw "Base cannot be applied directly.";}
        brands : {}
        method : function () { throw "Base cannot apply a method directly."; }
    };

    function PMethod(f) {
      this.method = f;
    }
    PMethod.prototype = new PBase();
    function makeMethod(f) { return new PMethod(f); } 
    function isMethod(v) { return v instanceof PMethod; }
    
    


    function PFunction(f) {
      this.app = f;
    }
    PFunction.prototype = new PBase();
    function makeFunction(f) { return new PFunction(f); }
    function isFunction(v) { return v instanceof PFunction; }
    

    var numberDict = {
      _plus: makeMethod(function(left, right) {
        return makeNumber(left.n + right.n);
      })
    };

    function PNumber(n) {
      this.n = n;
    }
    PNumber.prototype = new PBase();
    function makeNumber(n) { return new PNumber(n); }
    function isNumber(v) { return v instanceof PNumber; }
    PNumber.prototype.dict = numberDict;

    var stringDict = {
      _plus: makeMethod(function(left, right) {
        return makeString(left.s + right.s);
      })
    };

    function PString(s) {
      this.s = s;
    }
    PString.prototype = new PBase();
    function makeString(s) { return new PString(s); }
    function isString(v) { return v instanceof PString; }
    PString.prototype.dict = stringDict;      

    function PObject() {

    }
    PObject.prototype = new PBase();
    function makeObject() { return new PObject(); }
    function isObject(v) { return v instanceof PObject; }

    function PBoolean(v) {
      this.value = v;
    }
    PBoolean.prototype = new PBase();
    function makeBoolean(v) {
      return new PBoolean(v);
    }

    function isBoolean(v) { v instanceof PBoolean; }

    function makeFalse() { return makeBoolean(false); }
    function makeTrue() { return makeBoolean(false); }




    function equal(val1, val2) {
      if(isNumber(val1) && isNumber(val2)) {
        return val1.n === val2.n;
      }
      else if (isString(val1) && isString(val2)) {
        return val1.s === val2.s;
      }
      
      return false;
    }

    function toRepr(val) {
      if(isNumber(val)) {
        return makeString(String(val.n));
      }
      else if (isString(val)) {
        return makeString('"' + val.s + '"');
      }
      else if (isFunction(val)) {
        return makeString("fun: end");
      }
      else if (isMethod(val)) {
        return makeString("method: end");
      }
      throw ("toStringJS on an unknown type: " + val);
    }

    function getField(val, str) {
      var fieldVal = val.dict[str];
      if (isMethod(fieldVal)) {
        return makeFunction(function() {
          var argList = Array.prototype.slice.call(arguments);
          return fieldVal.method.apply(null, [val].concat(argList));
        });
      } else {
        return fieldVal;
      }
    }

    var testPrintOutput = "";
    function testPrint(val) {
      var str = toRepr(val).s;
      console.log("testPrint: ", val, str);
      testPrintOutput += str + "\n";
      return val;
    }

    function NormalResult(val) {
      this.val = val;
    }
    function makeNormalResult(val) { return new NormalResult(val); }

    function FailResult(exn) {
      this.exn = exn;
    }
    function makeFailResult(exn) { return new FailResult(exn); }

    function errToJSON(exn) {
      return JSON.stringify({exn: String(exn)})
    }

    return {
      nothing: {},
      makeNumber: makeNumber,
      isNumber: isNumber,
      equal: equal,
      getField: getField,
      getTestPrintOutput: function(val) {
        return testPrintOutput + toRepr(val).s;
      },
      NormalResult: NormalResult,
      FailResult: FailResult,
      makeNormalResult: makeNormalResult,
      makeFailResult: makeFailResult,
      toReprJS: toRepr,
      errToJSON: errToJSON,

      "test-print": makeFunction(testPrint),
    }
  }

  return {
    makeRuntime: makeRuntime
  };
})();

