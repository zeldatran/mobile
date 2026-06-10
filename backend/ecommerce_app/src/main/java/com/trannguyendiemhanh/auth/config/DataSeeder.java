package com.trannguyendiemhanh.auth.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import com.trannguyendiemhanh.auth.entity.Product;
import com.trannguyendiemhanh.auth.entity.Tag;
import com.trannguyendiemhanh.auth.repository.ProductRepository;
import com.trannguyendiemhanh.auth.repository.TagRepository;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

@Component
public class DataSeeder implements CommandLineRunner {

    private final ProductRepository productRepository;
    private final TagRepository tagRepository;

    @Autowired
    public DataSeeder(ProductRepository productRepository, TagRepository tagRepository) {
        this.productRepository = productRepository;
        this.tagRepository = tagRepository;
    }

    @Override
    public void run(String... args) throws Exception {
        if (productRepository.count() > 0) {
            System.out.println("Database already seeded with products.");
            return;
        }

        System.out.println("Seeding tags and products database...");

        // 1. Seed Tags
        Tag newTag = tagRepository.findByTagName("NEW").orElseGet(() -> {
            Tag tag = Tag.builder()
                    .tagName("NEW")
                    .icon("flash.svg")
                    .build();
            return tagRepository.save(tag);
        });

        Tag saleTag = tagRepository.findByTagName("SALE").orElseGet(() -> {
            Tag tag = Tag.builder()
                    .tagName("SALE")
                    .icon("percent")
                    .build();
            return tagRepository.save(tag);
        });

        Tag hotTag = tagRepository.findByTagName("HOT").orElseGet(() -> {
            Tag tag = Tag.builder()
                    .tagName("HOT")
                    .icon("flame")
                    .build();
            return tagRepository.save(tag);
        });

        // 2. Seed Products
        // Product 1: Evening Dress (SALE, 15$ -> 12$)
        Product p1 = Product.builder()
                .productName("Evening Dress")
                .slug("evening-dress")
                .sku("DP-ED-001")
                .salePrice(new BigDecimal("12.00"))
                .comparePrice(new BigDecimal("15.00"))
                .buyingPrice(new BigDecimal("8.00"))
                .quantity(50)
                .shortDescription("Elegant pink evening dress with lace details.")
                .productDescription("Dorothy Perkins Evening Dress is perfect for cocktail parties and summer nights.")
                .productType("simple")
                .published(true)
                .disableOutOfStock(true)
                .image("assets/images/sale1.png")
                .note("Dorothy Perkins")
                .tags(new HashSet<>(Collections.singletonList(saleTag)))
                .build();
        productRepository.save(p1);

        // Product 2: Sport Dress (SALE, 22$ -> 19$)
        Product p2 = Product.builder()
                .productName("Sport Dress")
                .slug("sport-dress")
                .sku("S-SD-002")
                .salePrice(new BigDecimal("19.00"))
                .comparePrice(new BigDecimal("22.00"))
                .buyingPrice(new BigDecimal("12.00"))
                .quantity(35)
                .shortDescription("Comfortable long sleeve gray sport dress.")
                .productDescription("Sitlly Sport Dress is made from premium stretch cotton for athletic and casual comfort.")
                .productType("simple")
                .published(true)
                .disableOutOfStock(true)
                .image("assets/images/sale2.png")
                .note("Sitlly")
                .tags(new HashSet<>(Collections.singletonList(saleTag)))
                .build();
        productRepository.save(p2);

        // Product 3: Summer Dress (SALE, 14$ -> 12$)
        Product p3 = Product.builder()
                .productName("Summer Dress")
                .slug("summer-dress")
                .sku("DP-SD-003")
                .salePrice(new BigDecimal("12.00"))
                .comparePrice(new BigDecimal("14.00"))
                .buyingPrice(new BigDecimal("7.50"))
                .quantity(40)
                .shortDescription("Lightweight gray summer dress.")
                .productDescription("Dorothy Perkins Summer Dress is a light knit dress ideal for hot summer walks.")
                .productType("simple")
                .published(true)
                .disableOutOfStock(true)
                .image("assets/images/sale3.png")
                .note("Dorothy Perkins")
                .tags(new HashSet<>(Collections.singletonList(saleTag)))
                .build();
        productRepository.save(p3);

        // Product 4: T-Shirt Summer (NEW, 15$)
        Product p4 = Product.builder()
                .productName("T-Shirt Summer")
                .slug("t-shirt-summer")
                .sku("TS-001")
                .salePrice(new BigDecimal("15.00"))
                .comparePrice(BigDecimal.ZERO)
                .buyingPrice(new BigDecimal("6.00"))
                .quantity(100)
                .shortDescription("Red striped cotton summer t-shirt.")
                .productDescription("Premium cotton material t-shirt with classic red and white stripes.")
                .productType("simple")
                .published(true)
                .disableOutOfStock(true)
                .image("assets/images/new1.png")
                .note("Dorothy Perkins")
                .tags(new HashSet<>(Collections.singletonList(newTag)))
                .build();
        productRepository.save(p4);

        // Product 5: White Blouse (NEW, 20$)
        Product p5 = Product.builder()
                .productName("White Blouse")
                .slug("white-blouse")
                .sku("WB-002")
                .salePrice(new BigDecimal("20.00"))
                .comparePrice(BigDecimal.ZERO)
                .buyingPrice(new BigDecimal("9.50"))
                .quantity(80)
                .shortDescription("Classic white cotton blouse.")
                .productDescription("Perfect white blouse for formal or smart-casual styles.")
                .productType("simple")
                .published(true)
                .disableOutOfStock(true)
                .image("assets/images/new2.png")
                .note("StreetBrand")
                .tags(new HashSet<>(Collections.singletonList(newTag)))
                .build();
        productRepository.save(p5);

        System.out.println("Database seeding completed successfully!");
    }
}
