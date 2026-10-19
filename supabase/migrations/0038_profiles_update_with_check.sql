-- profiles: o UPDATE só podia alcançar a própria linha (using), mas a linha resultante não era conferida.
-- Com o with check, a linha depois do update também precisa ser da própria conta (não dá para reapontar o id).
-- Idempotente: alter policy pode rodar de novo sem efeito colateral.
alter policy "Users can update own profile"
  on public.profiles
  using (auth.uid() = id)
  with check (auth.uid() = id);
