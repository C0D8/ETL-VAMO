(* lib/order_processing.ml *)

type order_status = Pending | Complete | Cancelled
(** Status de um pedido: pendente, concluído ou cancelado. *)

type order_origin = Paraphysical | Online
(** Origem de um pedido: loja física (Paraphysical) ou online (Online). *)

type order = {
  id : int;
  client_id : int;
  order_date : string;
  status : order_status;
  origin : order_origin;
}
(** Representa um pedido com identificador, cliente, data, status e origem. *)

type order_item = {
  order_id : int;
  product_id : int;
  quantity : int;
  price : float;
  tax : float;
}
(** Representa um item de um pedido com identificador do pedido, produto, quantidade, preço e imposto. *)

type order_summary = {
  order_id : int;
  total_amount : float;
  total_taxes : float;
}
(** Resumo de um pedido com identificador, valor total e total de impostos. *)

(** Converte uma string em um status de pedido.
    @param str String representando o status ("Pending", "Complete" ou "Cancelled").
    @return O valor correspondente do tipo [order_status].
    @raise Failure se o status for inválido, com uma mensagem indicando o valor recebido. *)
let status_of_string str =
  match str with
  | "Pending" -> Pending
  | "Complete" -> Complete
  | "Cancelled" -> Cancelled
  | _ -> failwith (Printf.sprintf "Invalid status: '%s'" str)

(** Converte uma string em uma origem de pedido.
    @param str String representando a origem ("P" para Paraphysical, "O" para Online).
    @return O valor correspondente do tipo [order_origin].
    @raise Failure se a origem for inválida, com uma mensagem indicando o valor recebido. *)
let origin_of_string str =
  match str with
  | "P" -> Paraphysical
  | "O" -> Online
  | _ -> failwith (Printf.sprintf "Invalid origin: expected 'P' or 'O', got '%s'" str)

(** Cria um pedido a partir de uma lista de strings.
    @param lst Lista com 5 elementos: [id; client_id; order_date; status; origin].
    @return Um record do tipo [order] com os campos preenchidos.
    @raise Failure se a lista não tiver exatamente 5 elementos ou se os valores forem inválidos. *)
let order_of_list = function
  | [id; client_id; order_date; status; origin] ->
      {
        id = int_of_string id;
        client_id = int_of_string client_id;
        order_date;
        status = status_of_string status;
        origin = origin_of_string origin;
      }
  | _ -> failwith "Invalid order data"

(** Cria um item de pedido a partir de uma lista de strings.
    @param lst Lista com 5 elementos: [order_id; product_id; quantity; price; tax].
    @return Um record do tipo [order_item] com os campos preenchidos.
    @raise Failure se a lista não tiver exatamente 5 elementos ou se os valores forem inválidos. *)
let order_item_of_list = function
  | [order_id; product_id; quantity; price; tax] ->
      {
        order_id = int_of_string order_id;
        product_id = int_of_string product_id;
        quantity = int_of_string quantity;
        price = float_of_string price;
        tax = float_of_string tax;
      }
  | _ -> failwith "Invalid order item data"

(** Calcula a receita de um item de pedido.
    @param item O item do tipo [order_item] para o qual a receita será calculada.
    @return A receita, calculada como quantidade multiplicada pelo preço (quantity * price). *)
let calculate_item_revenue item =
  float_of_int item.quantity *. item.price

(** Calcula o imposto de um item de pedido.
    @param item O item do tipo [order_item] para o qual o imposto será calculado.
    @return O imposto, calculado como a receita multiplicada pelo percentual de imposto (revenue * (tax / 100)).
    @note Assume que [tax] é um valor percentual (ex.: 0.05 para 5%). *)
let calculate_item_tax item =
  calculate_item_revenue item *. (item.tax)

(** Agrupa itens de pedido por identificador de pedido.
    @param items Lista de itens do tipo [order_item].
    @return Uma lista de pares [(order_id, itens)], onde cada [order_id] está associado aos seus itens correspondentes. *)
let group_items_by_order (items : order_item list) : (int * order_item list) list =
  let add_to_map map (item : order_item) =
    let current = try List.assoc item.order_id map with Not_found -> [] in
    (item.order_id, item :: current) :: (List.remove_assoc item.order_id map)
  in
  List.fold_left add_to_map [] items

(** Resume um pedido calculando o total da receita e dos impostos.
    @param order O pedido do tipo [order] a ser resumido.
    @param items Lista de pares [(order_id, itens)] contendo os itens associados a cada pedido.
    @return Um record do tipo [order_summary] com o identificador do pedido, total da receita e total dos impostos. *)
let summarize_order (order : order) (items : (int * order_item list) list) : order_summary =
  let order_items = List.assoc_opt order.id items |> Option.value ~default:[] in
  let total_amount = List.fold_left (fun acc item -> acc +. calculate_item_revenue item) 0.0 order_items in
  let total_taxes = List.fold_left (fun acc item -> acc +. calculate_item_tax item) 0.0 order_items in
  { order_id = order.id; total_amount; total_taxes }

(** Processa uma lista de pedidos, filtrando por status e origem, e gera resumos.
    @param orders Lista de pedidos do tipo [order].
    @param items Lista de itens do tipo [order_item].
    @param status Status desejado para filtragem (ex.: [Complete]).
    @param origin Origem desejada para filtragem (ex.: [Online]).
    @return Uma lista de [order_summary] contendo os resumos dos pedidos filtrados. *)
let process_orders (orders : order list) (items : order_item list) (status : order_status) (origin : order_origin) : order_summary list =
  let filtered_orders =
    List.filter
      (fun o -> o.status = status && o.origin = origin)
      orders
  in
  let grouped_items = group_items_by_order items in
  List.map (fun order -> summarize_order order grouped_items) filtered_orders

(** Extrai o ano e mês de uma data no formato "YYYY-MM-DDTHH:MM:SS".
    @param date String representando a data.
    @return Uma tupla (ano, mês) como strings.
    @raise Invalid_argument se o formato da data for inválido. *)
let extract_year_month date =
  let parts = String.split_on_char '-' date in
  match parts with
  | year :: month :: _ -> (year, month)
  | _ -> invalid_arg "Invalid date format"

(** Calcula a média de receita e impostos agrupada por mês e ano.
    @param orders Lista de pedidos do tipo [order].
    @param summaries Lista de resumos do tipo [order_summary].
    @return Uma lista de tuplas (year, month, avg_amount, avg_taxes). *)
let calculate_monthly_avg orders summaries =
  let month_map = ref [] in
  List.iter (fun summary ->
    let order = List.find (fun o -> o.id = summary.order_id) orders in
    let year, month = extract_year_month order.order_date in
    let key = (year, month) in
    let current = try List.assoc key !month_map with Not_found -> ([], []) in
    let amounts, taxes = current in
    month_map := (key, (summary.total_amount :: amounts, summary.total_taxes :: taxes)) :: (List.remove_assoc key !month_map)
  ) summaries;
  
  List.map (fun ((year, month), (amounts, taxes)) ->
    let count = float_of_int (List.length amounts) in
    let avg_amount = (List.fold_left (+.) 0.0 amounts) /. count in
    let avg_taxes = (List.fold_left (+.) 0.0 taxes) /. count in
    (year, month, avg_amount, avg_taxes)
  ) !month_map