package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Order;
import com.trannguyendiemhanh.auth.service.OrderService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/orders")
public class OrderController extends CrudController<Order, String> {
    public OrderController(OrderService service) {
        super(service);
    }
}
