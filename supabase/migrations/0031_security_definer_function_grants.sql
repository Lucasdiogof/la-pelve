-- Security: restrict SECURITY DEFINER helpers to their intended callers.
-- The auth.users trigger invokes handle_new_user internally, not through the REST API.
-- delete_own_account is a signed-in user action and rejects an empty auth.uid().
-- No application data is changed.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
