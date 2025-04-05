(* bin/main.ml *)
open Order_processing

(** Lê um arquivo CSV e retorna seus dados, ignorando o cabeçalho.
    @param filename Caminho do arquivo CSV a ser lido.
    @return Uma lista de listas de strings representando as linhas de dados (sem o cabeçalho).
    @raise Failure se o arquivo estiver vazio. *)
let read_csv filename =
  let all_rows = Csv.load filename in
  match all_rows with
  | _ :: data -> data
  | [] -> failwith "Empty CSV file"

(** Escreve uma lista de resumos de pedidos em um arquivo CSV.
    @param filename Caminho do arquivo CSV de saída.
    @param summaries Lista de resumos do tipo [order_summary] a ser gravada.
    @note Gera um CSV com cabeçalhos "order_id,total_amount,total_taxes". *)
let write_csv filename summaries =
  let headers = ["order_id"; "total_amount"; "total_taxes"] in
  let rows = List.map
    (fun s -> [string_of_int s.order_id; Printf.sprintf "%.2f" s.total_amount; Printf.sprintf "%.2f" s.total_taxes])
    summaries
  in
  Csv.save filename (headers :: rows)

(** Escreve as médias mensais de receita e impostos em um arquivo CSV.
    @param filename Caminho do arquivo CSV de saída.
    @param monthly_avgs Lista de tuplas (year, month, avg_amount, avg_taxes).
    @note Gera um CSV com cabeçalhos "year,month,avg_amount,avg_taxes". *)
let write_monthly_avg_csv filename monthly_avgs =
  let headers = ["year"; "month"; "avg_amount"; "avg_taxes"] in
  let rows = List.map (fun (year, month, avg_amount, avg_taxes) ->
    [year; month; Printf.sprintf "%.2f" avg_amount; Printf.sprintf "%.2f" avg_taxes]
  ) monthly_avgs in
  Csv.save filename (headers :: rows)

(** Função principal que processa pedidos e gera relatórios CSV.
    @note Aceita argumentos de linha de comando [--status] e [--origin] para filtrar os pedidos.
    @note Gera "output2.csv" com resumos e "monthly_avg.csv" com médias por mês/ano.
    @raise Failure se os argumentos fornecidos forem inválidos ou os arquivos CSV não puderem ser lidos. *)
let main () =
  let status = ref "Complete" in
  let origin = ref "O" in
  let speclist = [
    ("--status", Arg.Set_string status, "Status do pedido (Pending, Complete, Cancelled)");
    ("--origin", Arg.Set_string origin, "Origem do pedido (P para Paraphysical, O para Online)");
  ] in
  let usage_msg = "Uso: dune exec ./bin/main.exe -- [--status STATUS] [--origin ORIGIN]" in
  Arg.parse speclist print_endline usage_msg;
  
  let orders_data = read_csv "data/order.csv" in
  let items_data = read_csv "data/order_item.csv" in
  let orders = List.map order_of_list orders_data in
  let items = List.map order_item_of_list items_data in
  let status_val = status_of_string !status in
  let origin_val = origin_of_string !origin in
  let summaries = process_orders orders items status_val origin_val in
  write_csv "output5.csv" summaries;
  let monthly_avgs = calculate_monthly_avg orders summaries in
  write_monthly_avg_csv "monthly_avg.csv" monthly_avgs

let () = main ()