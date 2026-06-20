package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.OrderItem;
import com.trannguyendiemhanh.auth.repository.OrderItemRepository;
import com.trannguyendiemhanh.auth.service.OrderItemService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class OrderItemServiceImpl extends JpaCrudServiceImpl<OrderItem, UUID> implements OrderItemService {
    public OrderItemServiceImpl(OrderItemRepository repository) {
        super(repository);
    }
}
