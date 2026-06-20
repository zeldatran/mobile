package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.ProductShippingInfo;
import com.trannguyendiemhanh.auth.service.ProductShippingInfoService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/product-shipping-info")
public class ProductShippingInfoController extends CrudController<ProductShippingInfo, UUID> {
    public ProductShippingInfoController(ProductShippingInfoService service) {
        super(service);
    }
}
