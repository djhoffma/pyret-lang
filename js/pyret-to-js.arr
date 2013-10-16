#lang pyret

import ast as A
import json as J
import format as format

provide *
#helper function that turns pyret identifiers into
#javascript by getting rid of dashes. Creates a unique identifier for
#each one using gensym.
js-id-of = block:
  var js-ids = {}
  fun(id :: String):
    if builtins.has-field(js-ids, id):
      js-ids.[id]
    else:
      no-hyphens = id.replace("-", "_DASH_")
      safe-id = gensym(no-hyphens)
      js-ids := js-ids.{ [id]: safe-id } #wrap in a list to reduce to eq? equality.
      safe-id
    end
  end
end

fun program-to-js(ast, runtime-ids):
  cases(A.Program) ast:
    # import/provide in the target program ignored
    | s_program(_, _, block) =>
      bindings = for list.fold(bs from "", id from runtime-ids):
        bs + format("var ~a = RUNTIME['~a'];\n", [js-id-of(id), id])
      end
      format("(function(RUNTIME) {
        try {
          ~a
          return RUNTIME.makeNormalResult(~a);
        } catch(e) {
          return RUNTIME.makeFailResult(e);
        }
       })", [bindings, expr-to-js(block)])
  end
end

fun do-block(str):
  format("(function() { ~a })()", [str])
end

fun expr-to-js(ast):
  cases(A.Expr) ast:
	| s_user_block 
    | s_block(_, stmts) =>
      if stmts.length() == 0:
        "RUNTIME.nothing"
      else:
        fun sequence-return-last(ss):
          cases(list.List) ss:
            | link(f, r) =>
              cases(list.List) r:
                | empty => format("return ~a;", [expr-to-js(f)])
                | link(_, _) =>
                  format("~a;\n", [expr-to-js(f)]) + sequence-return-last(r)
              end
          end
        end
        format("(function(){\n ~a \n})()", [sequence-return-last(stmts)])
      end
    | s_num(_, n) =>
      format("RUNTIME.makeNumber(~a)", [n])
    | s_app(_, f, args) =>
      format("~a.app(~a)", [expr-to-js(f), args.map(expr-to-js).join-str(",")])
    | s_bracket(_, obj, f) =>
      cases (A.Expr) f:
        | s_str(_, s) => format("RUNTIME.getField(~a, '~a')", [expr-to-js(obj), s])
        | else => raise("Non-string lookups not supported")
      end
    | s_id(_, id) => js-id-of(id)
    | s_var(_, name, value) => format("var ~a = ~a;", [name, expr-to-js(value)])
    | s_let(_, name, value) => format("var ~a = ~a;", [name, expr-to-js(value)])
    | s_assign(_, id, value) => format("~a = ~a"), [id, expr-to-js(value)])
    | s_if_else(_, branches, _else) => generate-if-else-js(ast)
    | s_try(_, body, id, _except) =>
		format(" function () try{
					return ~a
				}
				catch(~a) {
					return ~a
				}()", [expr-to-js(body), id, expr-to-js(_except)])
	| s_lam(_, _, args, _, doc, body, _) =>
		format("makeFunction(function(~a){~a})", [args.map(fun (binding): binding.id).join-str(","), expr-to-js(body)])
	| s_method(_, args, _, doc, body, _) => 
		format("makeMethod(function(~a){~a})", [args.map(fun (binding): binding.id).join-str(","), expr-to-js(body)])
	| s_obj(_, fields) => make-js-obj(fields)
  | s_extend(_, super, fields) => #extends super with a list of new members.
	format("extendObj(~a, ~a)", [expr-to-js(super), make-js-obj(fields)])
#immutable change.
  | s_bool(_, b) => if b: "makeTrue()" else: "makeFalse()"
  | s_bracket(_, obj, field) => #lookup field based on string.
  | s_get_bang(_, obj, field) => #lookup mutable field based on string.
  | s_update(_, super, fields) => #update all the given fields, or none of them.
  | else => do-block(format("throw new Error('Not yet implemented ~a')", [torepr(ast)]))
  end
end

fun generate-if-else-js(ast):
	cases (A.Expr) ast:
		| s_if_else(_, branches, _else) =>
			var generating-else = false
			fun generate-branches(branches):
				cases (List<A.IfBranch>) branches:
					|empty => format("else { ~a; }", [expr-to-js(_else)])
					|link(head, rest) => 
						ret = format("~aif(~a) {
								return ~a;
							}
							~a",, [if generate-else: "else " else: "";,
							expr-to-js(head.test), expr-to-js(head.body),
							generate-branches(rest)])
							generate-else := true
							ret
				end
			end		
			format("function() { ~a }();", [generate-branches(branches)])
		| else => raise("cannot make if-else from non if-else expr")
end
fun make-js-obj(fields):
  fun inner-list-first(fields-begin):
          cases (List<Member>) fields-begin:
            | empty => ""
            | link(f, r) => format("~a~a", member-to-js(f), inner-list-rest(r))
          end
  end
  fun inner-list-rest(fields-rest):
          cases (List<Member) fields-rest:
            | empty => ""
            | link(f, r) => format(", ~a~a", member-to-js(f), inner-list-rest(r))
          end
  end
  format("makeObj({~a})", inner-list-first(fields))
end
fun member-to-js(member, mutables):
        cases (Member) member:
                | s_data_field(_, name, value) =>
                  format("~a : ~a", name.s, expr-to-js(value))
		end
end
fun make-js-function(params, 
