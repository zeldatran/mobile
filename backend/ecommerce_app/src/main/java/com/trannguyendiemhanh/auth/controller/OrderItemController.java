package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.OrderItem;
import com.trannguyendiemhanh.auth.service.OrderItemService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/order-items")
public class OrderItemController extends CrudController<OrderItem, UUID> {
    public OrderItemController(OrderItemService service) {
        super(service);
    }
}
