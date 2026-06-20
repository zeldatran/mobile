package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Order;
import com.trannguyendiemhanh.auth.repository.OrderRepository;
import com.trannguyendiemhanh.auth.service.OrderService;
import org.springframework.stereotype.Service;

@Service
public class OrderServiceImpl extends JpaCrudServiceImpl<Order, String> implements OrderService {
    public OrderServiceImpl(OrderRepository repository) {
        super(repository);
    }
}
