package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.OrderStatus;
import com.trannguyendiemhanh.auth.repository.OrderStatusRepository;
import com.trannguyendiemhanh.auth.service.OrderStatusService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class OrderStatusServiceImpl extends JpaCrudServiceImpl<OrderStatus, UUID> implements OrderStatusService {
    public OrderStatusServiceImpl(OrderStatusRepository repository) {
        super(repository);
    }
}
