{
  dbs = [
    {
      path = "/data/freshrss/users/_/db.sqlite";
      replicas = [{
        url = "\${LITESTREAM_R2_URL}/_";
        endpoint = "\${LITESTREAM_R2_ENDPOINT}";
      }];
    }
    {
      path = "/data/freshrss/users/kalaclista/db.sqlite";
      replicas = [{
        url = "\${LITESTREAM_R2_URL}/kalaclista";
        endpoint = "\${LITESTREAM_R2_ENDPOINT}";
      }];
    }
  ];
}
