package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Variant;
import com.trannguyendiemhanh.auth.service.VariantService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/variants")
public class VariantController extends CrudController<Variant, UUID> {
    public VariantController(VariantService service) {
        super(service);
    }
}
