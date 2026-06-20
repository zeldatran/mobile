package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Sell;
import com.trannguyendiemhanh.auth.service.SellService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/sells")
public class SellController extends CrudController<Sell, UUID> {
    public SellController(SellService service) {
        super(service);
    }
}
