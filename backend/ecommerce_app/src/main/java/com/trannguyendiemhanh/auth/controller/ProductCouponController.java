package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.ProductCoupon;
import com.trannguyendiemhanh.auth.service.ProductCouponService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/product-coupons")
public class ProductCouponController extends CrudController<ProductCoupon, UUID> {
    public ProductCouponController(ProductCouponService service) {
        super(service);
    }
}
