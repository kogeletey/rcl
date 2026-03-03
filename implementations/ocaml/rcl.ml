module SM = Map.Make(String)

type num = I of int | F of float
and node = NS of string | NN of num | NB of bool | NA of node list
and block = { name:string; arg:string option; props:(string*node) list; blocks:block list; named:block list }
and token = { t:string; v:string; l:int; c:int }
and lexer = { s:string; mutable p:int; mutable l:int; mutable c:int }
and value = VS of string | VN of num | VB of bool | VA of value list | VO of value SM.t

let err l c m = failwith (Printf.sprintf "%s at line %d, column %d" m l c)
let mk t v l c = {t;v;l;c}
let ch lx i = if i < String.length lx.s then Some lx.s.[i] else None
let cur lx = ch lx lx.p
let adv lx = match cur lx with Some '\n' -> lx.p<-lx.p+1; lx.l<-lx.l+1; lx.c<-1 | Some _ -> lx.p<-lx.p+1; lx.c<-lx.c+1 | None -> ()
let rec skip lx = match cur lx with
  | Some (' '|'\t'|'\r'|'\n') -> adv lx; skip lx
  | Some '#' -> while cur lx <> Some '\n' && cur lx <> None do adv lx done; skip lx
  | _ -> ()
let is_num c = c >= '0' && c <= '9'
let is_i0 c = (c>='a'&&c<='z')||(c>='A'&&c<='Z')||c='_'
let is_i c = is_i0 c || is_num c
let rec take lx f b = match cur lx with Some c when f c -> Buffer.add_char b c; adv lx; take lx f b | _ -> ()
let read_str lx l c =
  adv lx; let b = Buffer.create 16 in
  let rec loop () = match cur lx with
    | None -> err l c "Unterminated string"
    | Some '"' -> adv lx; mk "STRING" (Buffer.contents b) l c
    | Some '\\' -> adv lx; (match cur lx with
        | Some '"' -> Buffer.add_char b '"'
        | Some 'n' -> Buffer.add_char b '\n'
        | Some 't' -> Buffer.add_char b '\t'
        | Some '\\' -> Buffer.add_char b '\\'
        | Some _ -> err lx.l lx.c "Invalid escape sequence"
        | None -> err l c "Unterminated escape"); adv lx; loop ()
    | Some x -> Buffer.add_char b x; adv lx; loop ()
  in loop ()
let read_num lx l c =
  let b = Buffer.create 16 in
  (match cur lx with Some '-' -> Buffer.add_char b '-'; adv lx | _ -> ());
  take lx is_num b;
  (match cur lx, ch lx (lx.p+1) with Some '.', Some d when is_num d -> Buffer.add_char b '.'; adv lx; take lx is_num b | _ -> ());
  mk "NUMBER" (Buffer.contents b) l c
let read_ident lx l c =
  let b = Buffer.create 16 in take lx is_i b;
  let v = Buffer.contents b in mk (if v="do" then "DO" else if v="end" then "END" else "IDENT") v l c
let next lx =
  skip lx; match cur lx with
  | None -> mk "EOF" "" lx.l lx.c
  | Some '=' -> let l,c=lx.l,lx.c in adv lx; mk "EQ" "=" l c
  | Some ',' -> let l,c=lx.l,lx.c in adv lx; mk "COMMA" "," l c
  | Some '.' -> let l,c=lx.l,lx.c in adv lx; mk "DOT" "." l c
  | Some '[' -> let l,c=lx.l,lx.c in adv lx; mk "LBRACK" "[" l c
  | Some ']' -> let l,c=lx.l,lx.c in adv lx; mk "RBRACK" "]" l c
  | Some '"' -> read_str lx lx.l lx.c
  | Some '\'' -> err lx.l lx.c "single-quoted string usage"
  | Some '/' when ch lx (lx.p+1)=Some '/' -> err lx.l lx.c "unexpected character '/'"
  | Some c when is_num c || (c='-' && (match ch lx (lx.p+1) with Some d -> is_num d | _ -> false)) -> read_num lx lx.l lx.c
  | Some c when is_i0 c -> read_ident lx lx.l lx.c
  | Some c -> err lx.l lx.c (Printf.sprintf "unexpected character '%c'" c)

let parse s =
  let lx = {s; p=0; l=1; c=1} in
  let cur = ref (next lx) in
  let eat t = if (!cur).t<>t then err (!cur).l (!cur).c ("Expected "^t^", got "^(!cur).t) else cur := next lx in
  let peek () = let p,l,c=lx.p,lx.l,lx.c in let t=next lx in lx.p<-p; lx.l<-l; lx.c<-c; t in
  let split_dot k = String.split_on_char '.' k in
  let is_pref a b =
    let rec go x y = match x,y with [],_::_ -> true | hx::tx, hy::ty when hx=hy -> go tx ty | _ -> false in go a b in
  let ensure seen k =
    if List.mem k !seen then err (!cur).l (!cur).c ("Duplicate key '"^k^"'");
    let p = split_dot k in
    List.iter (fun ex -> let ep=split_dot ex in if is_pref p ep || is_pref ep p then err (!cur).l (!cur).c ("Key conflict between '"^k^"' and '"^ex^"'")) !seen;
    seen := k :: !seen
  in
  let rec prop_key () =
    let k = (!cur).v in eat "IDENT";
    let rec more acc = if (!cur).t="DOT" then (eat "DOT"; if (!cur).t<>"IDENT" then err (!cur).l (!cur).c "Expected identifier after dot"; let v=(!cur).v in eat "IDENT"; more (acc^"."^v)) else acc in
    more k
  and value () = match (!cur).t with
    | "STRING" -> let v=(!cur).v in eat "STRING"; NS v
    | "NUMBER" -> let v=(!cur).v in eat "NUMBER"; NN (if String.contains v '.' then F (float_of_string v) else I (int_of_string v))
    | "IDENT" -> let v=(!cur).v in eat "IDENT"; if v="true" then NB true else if v="false" then NB false else err (!cur).l (!cur).c ("Invalid bare value '"^v^"'")
    | "LBRACK" -> arr ()
    | _ -> err (!cur).l (!cur).c ("Unexpected token: "^(!cur).t)
  and arr () =
    eat "LBRACK"; let rec elems acc =
      if (!cur).t="RBRACK" then List.rev acc else
      let acc = value()::acc in
      if (!cur).t="COMMA" then (if (peek()).t="RBRACK" then err (!cur).l (!cur).c "Trailing comma in array"; eat "COMMA"; elems acc) else List.rev acc
    in let e=elems [] in if (!cur).t<>"RBRACK" then err (!cur).l (!cur).c "Missing ]"; eat "RBRACK"; NA e
  and block () =
    let name=(!cur).v in eat "IDENT";
    let arg = if (!cur).t="STRING" then let a=(!cur).v in eat "STRING"; Some a else None in
    eat "DO";
    let props,blocks,named,seen = ref [], ref [], ref [], ref [] in
    while (!cur).t<>"END" do
      if (!cur).t="EOF" then err (!cur).l (!cur).c "missing 'end' for block";
      if (!cur).t<>"IDENT" then err (!cur).l (!cur).c ("expected identifier, got "^(!cur).t);
      let n = peek() in
      if n.t="DO" || n.t="STRING" then let b=block() in if b.arg=None then blocks:=!blocks@[b] else named:=!named@[b]
      else if n.t="EQ" || n.t="DOT" then let k=prop_key() in ensure seen k; eat "EQ"; props := !props @ [k, value()]
      else err (!cur).l (!cur).c ("invalid statement after '"^(!cur).v^"'")
    done;
    eat "END";
    { name = name; arg = arg; props = !props; blocks = !blocks; named = !named }
  in
  let rec roots a = if (!cur).t="EOF" then List.rev a else roots (block()::a) in
  roots []

let esc s = String.concat "" (List.map (function '"'->"\\\""|'\\'->"\\\\"|'\n'->"\\n"|'\t'->"\\t"|c->String.make 1 c) (List.init (String.length s) (String.get s)))
let q s = "\""^esc s^"\""
let rec fmt_v = function NS s->q s | NN (I n)->string_of_int n | NN(F f)->Printf.sprintf "%g" f | NB b->if b then "true" else "false" | NA xs->"["^String.concat ", " (List.map fmt_v xs)^"]"
let rec fmt_b i b =
  let pad = String.make (2*i) ' ' in
  let h = if b.arg=None then pad^b.name^" do" else pad^b.name^" "^q (Option.get b.arg)^" do" in
  let p = List.map (fun (k,v)->pad^"  "^k^" = "^fmt_v v) b.props in
  let c = List.map (fmt_b (i+1)) (b.blocks@b.named) in
  String.concat "\n" (h::(p@c@[pad^"end"]))
let format_rcl d = String.concat "\n\n" (List.map (fmt_b 0) d)

let rec node_val = function NS s->VS s | NN n->VN n | NB b->VB b | NA xs->VA(List.map node_val xs)
let rec insert_path m parts v = match parts with
  | [] -> m
  | [k] -> if SM.mem k m then failwith ("duplicate key '"^k^"'") else SM.add k v m
  | k::rest ->
    let o = match SM.find_opt k m with None->SM.empty | Some (VO o)->o | _->failwith ("key conflict at '"^k^"'") in
    SM.add k (VO (insert_path o rest v)) m
let named_base n = if String.length n > 0 && n.[String.length n - 1] = 's' then n else n ^ "s"
let rec block_obj b =
  let m = List.fold_left (fun a (k,v)-> insert_path a (split_on_char '.' k) (node_val v)) SM.empty b.props in
  let m =
    List.fold_left
      (fun a c ->
        let child = block_obj c in
        match SM.find_opt c.name a with
        | Some (VO ex) -> SM.add c.name (VO (SM.union (fun _ n _ -> Some n) child ex)) a
        | _ -> SM.add c.name (VO child) a)
      m b.blocks
  in
  List.fold_left (fun a c -> let base=named_base c.name in let ex=match SM.find_opt base a with Some(VO o)->o | _->SM.empty in SM.add base (VO (SM.add (Option.get c.arg) (VO (block_obj c)) ex)) a) m b.named
and split_on_char = String.split_on_char
let to_object d =
  List.fold_left (fun a b -> if b.arg=None then SM.add b.name (VO(block_obj b)) a else SM.add (named_base b.name) (VO (SM.singleton (Option.get b.arg) (VO(block_obj b)))) a) SM.empty d
let rec scalar = function VS s->q s | VN(I n)->string_of_int n | VN(F f)->Printf.sprintf "%g" f | VB b->if b then "true" else "false" | VA xs->"["^String.concat ", " (List.map scalar xs)^"]" | VO _->"{}"
let rec yaml i = function
  | VA xs -> String.concat "\n" (List.map (fun x -> let p=String.make (2*i) ' ' in match x with VO _ | VA _ -> p^"-\n"^yaml (i+1) x | _ -> p^"- "^scalar x) xs)
  | VO o -> String.concat "\n" (List.map (fun (k,v) -> let p=String.make (2*i) ' ' in match v with VO _ | VA _ -> p^k^":\n"^yaml (i+1) v | _ -> p^k^": "^scalar v) (SM.bindings o))
  | v -> String.make (2*i) ' '^scalar v
let to_yaml d = yaml 0 (VO (to_object d))
let to_toml d =
  let out = Buffer.create 128 in
  let rec walk p o =
    SM.iter (fun k v -> match v with VO _ -> () | _ -> Buffer.add_string out (k^" = "^scalar v^"\n")) o;
    SM.iter (fun k v -> match v with VO c -> if Buffer.length out>0 then Buffer.add_char out '\n'; Buffer.add_string out ("["^(if p="" then k else p^"."^k)^"]\n"); walk (if p="" then k else p^"."^k) c | _ -> ()) o
  in walk "" (to_object d); String.trim (Buffer.contents out)
let rec hcl i = function
  | VO o -> String.concat "\n" (List.map (fun (k,v) -> let p=String.make (2*i) ' ' in match v with VO _ -> p^k^" {\n"^hcl (i+1) v^"\n"^p^"}" | _ -> p^k^" = "^scalar v) (SM.bindings o))
  | v -> String.make (2*i) ' '^scalar v
let to_hcl d = hcl 0 (VO (to_object d))
