package com.ssafy.ollana.tracking.service;

import org.hibernate.resource.jdbc.spi.StatementInspector;

public class SQLInspector implements StatementInspector {
    @Override
    public String inspect(String sql) {
        System.out.println("📝 [Hibernate SQL] " + sql);
        return sql;
    }
}

